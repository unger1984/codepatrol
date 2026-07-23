#!/bin/bash
set -e

REPO_URL="https://github.com/unger1984/codepatrol.git"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Remote install: if templates/ not found locally, clone the repo to a temp dir
CLONED_DIR=""
if [ ! -d "$SCRIPT_DIR/templates/_shared" ]; then
    if ! command -v git &>/dev/null; then
        echo "Error: git is required for remote installation"
        exit 1
    fi
    CLONED_DIR=$(mktemp -d)
    echo "Cloning codepatrol..."
    git clone --depth 1 "$REPO_URL" "$CLONED_DIR" 2>/dev/null
    SCRIPT_DIR="$CLONED_DIR"
    trap 'rm -rf "$CLONED_DIR"' EXIT
fi

TEMPLATES_DIR="$SCRIPT_DIR/templates"
SKILLS_DIR="$SCRIPT_DIR/skills"
PLATFORMS_DIR="$SCRIPT_DIR/platforms"
LEGACY_SKILLS="cpatrol cpresume cpexecute cpplanreview cpplanfix cpreview cpfix cpdocs cprules cp-idea cp-plan cp-execute cp-plan-review cp-plan-fix cp-resume cp-docs cp-rules"
LEGACY_SKILL_A="code""-review"
LEGACY_SKILL_B="code""-review""-fix"

usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build    Generate skills/ from templates using Claude platform values"
    echo "  validate Generate all supported platforms to temp output and verify generated markdown"
    echo "  claude   Generate and install skills to ~/.claude/skills/"
    echo "  codex    Generate and install skills to ~/.codex/skills/"
    echo "  cursor   Generate and install skills to ~/.cursor/skills/"
    echo "  opencode Generate and install skills to ~/.config/opencode/skills/"
    echo "  omp      Generate and install skills to ~/.omp/agent/skills/"
    echo ""
    exit 1
}

clean_installed_skills() {
    local target_dir="$1"
    mkdir -p "$target_dir"

    # Clean current skills (derived from templates)
    for skill_dir in "$TEMPLATES_DIR"/*/; do
        local skill_name
        skill_name=$(basename "$skill_dir")
        [[ "$skill_name" == _* ]] && continue
        rm -rf "$target_dir/$skill_name"
    done

    # Clean legacy skill names from previous versions
    for skill_name in $LEGACY_SKILLS "$LEGACY_SKILL_A" "$LEGACY_SKILL_B"; do
        rm -rf "$target_dir/$skill_name"
    done
}

# Resolve {{@platform-include:filename}} directives by inlining _shared/filename-{platform}.md
# Usage: resolve_platform_includes <file> <base_dir> <platform>
resolve_platform_includes() {
    local file="$1"
    local base_dir="$2"
    local platform="$3"

    while grep -q '{{@platform-include:' "$file"; do
        local include_name
        local full_path
        local tmp

        include_name=$(grep -m1 -o '{{@platform-include:[^}]*}}' "$file" | sed 's/{{@platform-include://;s/}}//')
        full_path="$base_dir/_shared/${include_name}-${platform}.md"

        if [ ! -f "$full_path" ]; then
            echo "Error: platform include file not found: $full_path"
            exit 1
        fi

        # Replace the include line with file contents (portable across GNU/BSD)
        tmp="$file.pinc.tmp"
        awk -v pattern="{{@platform-include:${include_name}}}" -v inc="$full_path" '
            $0 ~ pattern { while ((getline line < inc) > 0) print line; close(inc); next }
            { print }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
    done
}

# Resolve {{@include:relative/path}} directives by inlining file contents
# Usage: resolve_includes <file> <base_dir>
resolve_includes() {
    local file="$1"
    local base_dir="$2"

    while grep -q '{{@include:' "$file"; do
        local include_path
        local full_path
        local tmp

        include_path=$(grep -m1 -o '{{@include:[^}]*}}' "$file" | sed 's/{{@include://;s/}}//')
        full_path="$base_dir/$include_path"

        if [ ! -f "$full_path" ]; then
            echo "Error: include file not found: $full_path"
            exit 1
        fi

        # Replace the include line with file contents (portable across GNU/BSD)
        tmp="$file.inc.tmp"
        awk -v pattern="{{@include:${include_path}}}" -v inc="$full_path" '
            $0 ~ pattern { while ((getline line < inc) > 0) print line; close(inc); next }
            { print }
        ' "$file" > "$tmp" && mv "$tmp" "$file"
    done
}

# Substitute placeholders in a template file using values from an env file
# Usage: substitute <template_file> <env_file> <output_file> <platform>
substitute() {
    local template="$1"
    local env_file="$2"
    local output="$3"
    local platform="$4"

    cp "$template" "$output"

    # Resolve platform-specific includes first, then generic includes
    resolve_platform_includes "$output" "$TEMPLATES_DIR" "$platform"
    resolve_includes "$output" "$TEMPLATES_DIR"

    # Read env file line by line and substitute each variable
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [ -z "$key" ] && continue
        [[ "$key" == \#* ]] && continue

        local placeholder
        placeholder="{{${key}}}"

        if [ -z "$value" ]; then
            # Empty value — remove the entire line containing the placeholder
            grep -v "$placeholder" "$output" > "$output.tmp" && mv "$output.tmp" "$output"
        else
            # Replace placeholder with value (awk handles literal strings via variable)
            awk -v ph="$placeholder" -v val="$value" '{
                idx = index($0, ph)
                while (idx > 0) {
                    $0 = substr($0, 1, idx-1) val substr($0, idx+length(ph))
                    idx = index($0, ph)
                }
                print
            }' "$output" > "$output.tmp" && mv "$output.tmp" "$output"
        fi
    done < <(cat "$env_file"; echo)
}

# Generate skills from templates for a given platform
# Usage: generate <platform> <output_dir>
generate() {
    local platform="$1"
    local output_dir="$2"
    local env_file="$PLATFORMS_DIR/${platform}.env"

    if [ ! -f "$env_file" ]; then
        echo "Error: platform file not found: $env_file"
        exit 1
    fi

    echo "Generating skills for $platform..."

    mkdir -p "$output_dir"

    # Process each template directory (skip _shared — it contains include-only files)
    for skill_dir in "$TEMPLATES_DIR"/*/; do
        local skill_name
        local out_skill_dir

        skill_name=$(basename "$skill_dir")
        [[ "$skill_name" == _* ]] && continue
        out_skill_dir="$output_dir/$skill_name"

        mkdir -p "$out_skill_dir"

        # Process each file in the skill directory
        for template_file in "$skill_dir"*.md; do
            local filename
            [ -f "$template_file" ] || continue
            filename=$(basename "$template_file")
            substitute "$template_file" "$env_file" "$out_skill_dir/$filename" "$platform"
        done

        echo "  $skill_name: done"
    done

    echo "Generated to: $output_dir"
}

validate_generated_markdown() {
    local platform="$1"
    local output_dir="$2"
    local file

    while IFS= read -r -d '' file; do
        if grep -Eq '{{@include:|{{@platform-include:|{{[A-Z][A-Z0-9_]*}}' "$file"; then
            echo "Error: unresolved template markers in $platform output: $file"
            exit 1
        fi
    done < <(find "$output_dir" -type f -name '*.md' -print0)

    grep -Fq 'requires_deep_compliance' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing requires_deep_compliance marker in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'prepared_context' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing prepared_context marker in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'architecture_risk' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing architecture_risk marker in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'compare every extracted requirement locally' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing local comparison marker in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'stop before quality with `NEEDS_CHANGES`' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing compliance gate marker in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'explicit verdict for every dimension' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing grouped verdict coverage in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'independent security review' "$output_dir/cp-review/SKILL.md" || {
        echo "Error: missing independent security routing in $platform cp-review/SKILL.md"
        exit 1
    }
    grep -Fq 'Fix Decision Brief' "$output_dir/cp-fix/SKILL.md" || {
        echo "Error: missing Fix Decision Brief in $platform cp-fix/SKILL.md"
        exit 1
    }
    grep -Fq 'Manual Per Item Gate' "$output_dir/cp-fix/SKILL.md" || {
        echo "Error: missing Manual Per Item Gate in $platform cp-fix/SKILL.md"
        exit 1
    }
    grep -Fq 'auto safe fixes' "$output_dir/cp-fix/SKILL.md" || {
        echo "Error: missing safe-auto policy in $platform cp-fix/SKILL.md"
        exit 1
    }
    grep -Fq 'prepared planning context' "$output_dir/using-codepatrol/SKILL.md" || {
        echo "Error: missing prepared planning context in $platform using-codepatrol/SKILL.md"
        exit 1
    }
    grep -Fq 'Planning check: classify the request before loading `brainstorming`.' "$output_dir/using-codepatrol/SKILL.md" || {
        echo "Error: missing direct-request planning gate in $platform using-codepatrol/SKILL.md"
        exit 1
    }
}

validate() {
    (
        local tmp_dir
        local output_dir
        local platform

        tmp_dir=$(mktemp -d)
        trap 'rm -rf "$tmp_dir"' EXIT

        for platform in claude codex cursor omp opencode; do
            output_dir="$tmp_dir/$platform"
            generate "$platform" "$output_dir"
            validate_generated_markdown "$platform" "$output_dir"
        done

        echo "Validation passed."
    )
}

case "${1:-}" in
    build)
        rm -rf "$SKILLS_DIR"
        generate "claude" "$SKILLS_DIR"
        ;;
    validate)
        validate
        ;;
    claude)
        local_dir="$HOME/.claude/skills"
        rm -rf "$SKILLS_DIR"
        generate "claude" "$SKILLS_DIR"
        clean_installed_skills "$local_dir"
        for skill_dir in "$SKILLS_DIR"/*/; do
            skill_name=$(basename "$skill_dir")
            target="$local_dir/$skill_name"
            cp -r "$skill_dir" "$target"
            echo "Installed: $target"
        done
        ;;
    codex)
        local_dir="$HOME/.codex/skills"
        legacy_dir="$HOME/.agents/skills"
        tmp_dir=$(mktemp -d)
        generate "codex" "$tmp_dir"
        clean_installed_skills "$legacy_dir"
        clean_installed_skills "$local_dir"
        for skill_dir in "$tmp_dir"/*/; do
            skill_name=$(basename "$skill_dir")
            target="$local_dir/$skill_name"
            cp -r "$skill_dir" "$target"
            echo "Installed: $target"
        done
        rm -rf "$tmp_dir"
        ;;
    cursor)
        local_dir="$HOME/.cursor/skills"
        tmp_dir=$(mktemp -d)
        generate "cursor" "$tmp_dir"
        clean_installed_skills "$local_dir"
        for skill_dir in "$tmp_dir"/*/; do
            skill_name=$(basename "$skill_dir")
            target="$local_dir/$skill_name"
            cp -r "$skill_dir" "$target"
            echo "Installed: $target"
        done
        rm -rf "$tmp_dir"
        ;;
    opencode)
        local_dir="$HOME/.config/opencode/skills"
        tmp_dir=$(mktemp -d)
        generate "opencode" "$tmp_dir"
        clean_installed_skills "$local_dir"
        for skill_dir in "$tmp_dir"/*/; do
            skill_name=$(basename "$skill_dir")
            target="$local_dir/$skill_name"
            cp -r "$skill_dir" "$target"
            echo "Installed: $target"
        done
        rm -rf "$tmp_dir"
        ;;
    omp)
        if ! command -v omp >/dev/null 2>&1; then
            echo "Error: omp is required for OMP installation"
            exit 1
        fi
        omp install "$SCRIPT_DIR"
        ;;
    *)
        usage
        ;;
esac

echo "Done."
