#Requires -Version 5.1
<#
.SYNOPSIS
    Build and install CodePatrol skills for Windows.
.DESCRIPTION
    PowerShell-версия install.sh — сборка и установка скиллов из шаблонов.
.EXAMPLE
    .\install.ps1 build
    .\install.ps1 claude
    .\install.ps1 codex
    .\install.ps1 cursor
    .\install.ps1 opencode
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('build', 'claude', 'codex', 'cursor', 'opencode')]
    [string]$Command
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/unger1984/codepatrol.git'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClonedDir = $null

# Удалённая установка: если templates/_shared нет рядом со скриптом — клонируем репо
if (-not (Test-Path (Join-Path $ScriptDir 'templates' '_shared'))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error 'Error: git is required for remote installation'
        exit 1
    }
    $ClonedDir = Join-Path ([System.IO.Path]::GetTempPath()) "codepatrol-$(Get-Random)"
    Write-Host 'Cloning codepatrol...'
    git clone --depth 1 $RepoUrl $ClonedDir 2>$null
    $ScriptDir = $ClonedDir
}

$TemplatesDir = Join-Path $ScriptDir 'templates'
$SkillsDir = Join-Path $ScriptDir 'skills'
$PlatformsDir = Join-Path $ScriptDir 'platforms'
$LegacySkills = @(
    'cpatrol', 'cpresume', 'cpexecute', 'cpplanreview', 'cpplanfix',
    'cpreview', 'cpfix', 'cpdocs', 'cprules', 'cp-idea', 'cp-plan',
    'cp-execute', 'cp-plan-review', 'cp-plan-fix', 'cp-resume',
    'cp-docs', 'cp-rules', 'code-review', 'code-review-fix'
)

function Show-Usage {
    Write-Host "Usage: .\install.ps1 <command>"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  build    Generate skills/ from templates using Claude platform values"
    Write-Host "  claude   Generate and install skills to ~/.claude/skills/"
    Write-Host "  codex    Generate and install skills to ~/.codex/skills/"
    Write-Host "  cursor   Generate and install skills to ~/.cursor/skills/"
    Write-Host "  opencode Generate and install skills to ~/.config/opencode/skills/"
    Write-Host ""
    exit 1
}

function Remove-InstalledSkills {
    param([string]$TargetDir)

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # Удаляем текущие скиллы (по именам из templates)
    foreach ($skillDir in Get-ChildItem -Path $TemplatesDir -Directory) {
        if ($skillDir.Name.StartsWith('_')) { continue }
        $target = Join-Path $TargetDir $skillDir.Name
        if (Test-Path $target) {
            Remove-Item -Recurse -Force $target
        }
    }

    # Удаляем legacy-скиллы
    foreach ($name in $LegacySkills) {
        $target = Join-Path $TargetDir $name
        if (Test-Path $target) {
            Remove-Item -Recurse -Force $target
        }
    }
}

function Resolve-PlatformIncludes {
    param(
        [string]$File,
        [string]$BaseDir,
        [string]$Platform
    )

    $content = Get-Content -Path $File -Raw -Encoding UTF8
    while ($content -match '\{\{@platform-include:([^}]+)\}\}') {
        $includeName = $Matches[1]
        $fullPath = Join-Path $BaseDir "_shared\${includeName}-${Platform}.md"

        if (-not (Test-Path $fullPath)) {
            Write-Error "Error: platform include file not found: $fullPath"
            exit 1
        }

        $includeContent = Get-Content -Path $fullPath -Raw -Encoding UTF8
        # Убираем trailing newline из включаемого файла, чтобы не дублировать
        $includeContent = $includeContent.TrimEnd("`r", "`n")
        $placeholder = "{{@platform-include:${includeName}}}"
        # Заменяем всю строку с placeholder на содержимое файла
        $content = $content -replace [regex]::Escape($placeholder), $includeContent
    }
    Set-Content -Path $File -Value $content -NoNewline -Encoding UTF8
}

function Resolve-Includes {
    param(
        [string]$File,
        [string]$BaseDir
    )

    $content = Get-Content -Path $File -Raw -Encoding UTF8
    while ($content -match '\{\{@include:([^}]+)\}\}') {
        $includePath = $Matches[1]
        $fullPath = Join-Path $BaseDir $includePath

        if (-not (Test-Path $fullPath)) {
            Write-Error "Error: include file not found: $fullPath"
            exit 1
        }

        $includeContent = Get-Content -Path $fullPath -Raw -Encoding UTF8
        $includeContent = $includeContent.TrimEnd("`r", "`n")
        $placeholder = "{{@include:${includePath}}}"
        $content = $content -replace [regex]::Escape($placeholder), $includeContent
    }
    Set-Content -Path $File -Value $content -NoNewline -Encoding UTF8
}

function Invoke-Substitute {
    param(
        [string]$Template,
        [string]$EnvFile,
        [string]$Output,
        [string]$Platform
    )

    Copy-Item -Path $Template -Destination $Output -Force

    Resolve-PlatformIncludes -File $Output -BaseDir $TemplatesDir -Platform $Platform
    Resolve-Includes -File $Output -BaseDir $TemplatesDir

    # Подставляем переменные из env-файла
    $content = Get-Content -Path $Output -Raw -Encoding UTF8
    foreach ($line in Get-Content -Path $EnvFile -Encoding UTF8) {
        $line = $line.Trim()
        if ([string]::IsNullOrEmpty($line) -or $line.StartsWith('#')) { continue }

        $eqIndex = $line.IndexOf('=')
        if ($eqIndex -lt 0) { continue }

        $key = $line.Substring(0, $eqIndex)
        $value = $line.Substring($eqIndex + 1)
        $placeholder = "{{${key}}}"

        if ([string]::IsNullOrEmpty($value)) {
            # Пустое значение — удаляем строки с placeholder
            $content = ($content -split "`n" | Where-Object { $_ -notmatch [regex]::Escape($placeholder) }) -join "`n"
        }
        else {
            $content = $content.Replace($placeholder, $value)
        }
    }
    Set-Content -Path $Output -Value $content -NoNewline -Encoding UTF8
}

function Invoke-Generate {
    param(
        [string]$Platform,
        [string]$OutputDir
    )

    $envFile = Join-Path $PlatformsDir "${Platform}.env"
    if (-not (Test-Path $envFile)) {
        Write-Error "Error: platform file not found: $envFile"
        exit 1
    }

    Write-Host "Generating skills for $Platform..."

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    # Обрабатываем каждую директорию шаблонов (пропускаем _shared и прочие _*)
    foreach ($skillDir in Get-ChildItem -Path $TemplatesDir -Directory) {
        if ($skillDir.Name.StartsWith('_')) { continue }

        $outSkillDir = Join-Path $OutputDir $skillDir.Name
        if (-not (Test-Path $outSkillDir)) {
            New-Item -ItemType Directory -Path $outSkillDir -Force | Out-Null
        }

        foreach ($templateFile in Get-ChildItem -Path $skillDir.FullName -Filter '*.md') {
            Invoke-Substitute `
                -Template $templateFile.FullName `
                -EnvFile $envFile `
                -Output (Join-Path $outSkillDir $templateFile.Name) `
                -Platform $Platform
        }

        Write-Host "  $($skillDir.Name): done"
    }

    Write-Host "Generated to: $OutputDir"
}

# --- Main ---

if (-not $Command) {
    Show-Usage
}

switch ($Command) {
    'build' {
        if (Test-Path $SkillsDir) {
            Remove-Item -Recurse -Force $SkillsDir
        }
        Invoke-Generate -Platform 'claude' -OutputDir $SkillsDir
    }
    'claude' {
        $localDir = Join-Path $HOME '.claude\skills'
        if (Test-Path $SkillsDir) {
            Remove-Item -Recurse -Force $SkillsDir
        }
        Invoke-Generate -Platform 'claude' -OutputDir $SkillsDir
        Remove-InstalledSkills -TargetDir $localDir
        foreach ($skillDir in Get-ChildItem -Path $SkillsDir -Directory) {
            $target = Join-Path $localDir $skillDir.Name
            Copy-Item -Recurse -Force -Path $skillDir.FullName -Destination $target
            Write-Host "Installed: $target"
        }
    }
    'codex' {
        $localDir = Join-Path $HOME '.agents\skills'
        $legacyDir = Join-Path $HOME '.codex\skills'
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "codepatrol-$(Get-Random)"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        Invoke-Generate -Platform 'codex' -OutputDir $tmpDir
        Remove-InstalledSkills -TargetDir $legacyDir
        Remove-InstalledSkills -TargetDir $localDir
        foreach ($skillDir in Get-ChildItem -Path $tmpDir -Directory) {
            $target = Join-Path $localDir $skillDir.Name
            Copy-Item -Recurse -Force -Path $skillDir.FullName -Destination $target
            Write-Host "Installed: $target"
        }
        Remove-Item -Recurse -Force $tmpDir
    }
    'cursor' {
        $localDir = Join-Path $HOME '.cursor\skills'
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "codepatrol-$(Get-Random)"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        Invoke-Generate -Platform 'cursor' -OutputDir $tmpDir
        Remove-InstalledSkills -TargetDir $localDir
        foreach ($skillDir in Get-ChildItem -Path $tmpDir -Directory) {
            $target = Join-Path $localDir $skillDir.Name
            Copy-Item -Recurse -Force -Path $skillDir.FullName -Destination $target
            Write-Host "Installed: $target"
        }
        Remove-Item -Recurse -Force $tmpDir
    }
    'opencode' {
        $localDir = Join-Path $HOME '.config\opencode\skills'
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "codepatrol-$(Get-Random)"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        Invoke-Generate -Platform 'opencode' -OutputDir $tmpDir
        Remove-InstalledSkills -TargetDir $localDir
        foreach ($skillDir in Get-ChildItem -Path $tmpDir -Directory) {
            $target = Join-Path $localDir $skillDir.Name
            Copy-Item -Recurse -Force -Path $skillDir.FullName -Destination $target
            Write-Host "Installed: $target"
        }
        Remove-Item -Recurse -Force $tmpDir
    }
}

# Очистка клонированного репо
if ($ClonedDir -and (Test-Path $ClonedDir)) {
    Remove-Item -Recurse -Force $ClonedDir
}

Write-Host "Done."
