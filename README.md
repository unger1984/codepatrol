**English** | [Русский](README.ru.md)

# CodePatrol

Project-aware AI skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Codex CLI](https://github.com/openai/codex), [Cursor](https://cursor.com), [OpenCode](https://opencode.ai), and Oh My Pi / Pi. Enhances the standard [Superpowers](https://github.com/obra/superpowers) workflow with project rules and documentation awareness.

## Table of Contents

- [How It Works](#how-it-works)
- [Skills](#skills)
- [Data Storage](#data-storage)
- [Quick Start](#quick-start)
  - [Claude Code](#claude-code)
  - [Codex CLI](#codex-cli)
  - [Cursor](#cursor)
  - [OpenCode](#opencode)
  - [Oh My Pi](#oh-my-pi)
- [Usage](#usage)
- [Development](#development)
- [CI/CD](#cicd)
- [Known Limitations](#known-limitations)
- [License](#license)

## How It Works

CodePatrol integrates into the Superpowers skill chain (`brainstorming → writing-plans → executing-plans`) instead of replacing it:

```
brainstorming (superpowers)          writing-plans (superpowers)
+ CodePatrol enhancements:           + CodePatrol enhancements:
│                                    │
├─ Read project rules                ├─ Read project rules
├─ Read .ai/docs/                    ├─ Read .ai/docs/
├─ Check approaches vs rules         ├─ Include docs update step
├─ Save design to .ai/tasks/         ├─ Self-check plan vs rules
│                                    ├─ Save plan to .ai/tasks/
▼                                    ▼
writing-plans                        executing-plans / subagent-driven
                                     │
                                     ▼ (user decides)
                                     /cp-review → /cp-fix → /cp-docs
```

**What CodePatrol adds:**
- Project rules and documentation are read **before** design and planning
- Planning self-checks use a cited prepared context: artifact path/type, explicit requirements, only applicable rule/doc excerpts, approved-design excerpts for plans, and missing-context blockers
- Plans include documentation update steps only when existing docs actually need them
- `/cp-review` keeps compliance first, uses adaptive quality routing for large low-risk scope, and preserves independent security and architecture-risk review
- `/cp-fix` uses a Manual Per Item Gate plus `auto safe fixes` for one isolated safe option only
- Research-heavy docs/rules workflows use source maps (`path:line`, exact excerpt, relevance), and progress tracking is batched with the nearest real action when the platform supports it
- OMP support keeps duplicated output-schema text intentionally; CodePatrol does **not** add a YAML frontmatter include/preprocessor for that case

## Skills

| Skill | Purpose |
|-------|---------|
| `using-codepatrol` | Enhances brainstorming and writing-plans with project awareness |
| `/cp-review` | Mandatory local compliance triage, then quality after clean compliance; powerful compliance review only for applicable contracts or high-risk scopes |
| `/cp-fix` | Process and fix review findings with incremental tracking |
| `/cp-docs` | Create and maintain AI-facing project documentation |

## Data Storage

```
.ai/
├── tasks/                          # Task artifacts
│   └── YYYY-MM-DD-HHMM-slug/
│       ├── design.md               # Approved design
│       ├── plan.md                  # Implementation plan
│       └── review.md               # Code review report
├── docs/                           # AI-facing project documentation
│   └── README.md                   # Navigation hub
└── reports/                        # Ad-hoc review reports
```

## Quick Start

### Claude Code

**From latest release (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- claude
```

**From latest release (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 claude
```


### Codex CLI

**From latest release (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- codex
```

**From latest release (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 codex
```


### Cursor

**From latest release (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- cursor
```

**From latest release (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 cursor
```


### OpenCode

**From latest release (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- opencode
```

**From latest release (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 opencode
```


### Oh My Pi

**Primary install path (Pi):**
```bash
pi install git:github.com/unger1984/codepatrol
```

**Primary install path (OMP):**
```bash
omp install github:unger1984/codepatrol
```

**Fallback path (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- omp
```

**Fallback path (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 omp
```

Pi/OMP package installation relies on `pi` or `omp` being available on `PATH`, and the fallback OMP installer delegates to OMP package installation.

## Usage

### Start a new task

Just describe what you want to build. CodePatrol enhances brainstorming automatically:

```
> Let's add rate limiting to the API

# brainstorming reads your project rules and docs,
# asks clarifying questions, proposes approaches,
# checks them against your conventions,
# produces a design → then a plan
```

### Review code

```
> /cp-review
> /cp-review src/auth/
> /cp-review branch vs main
```

### Fix findings

```
> /cp-fix
> /cp-fix .ai/tasks/2026-03-09-1420-rate-limit/review.md
```

### Update documentation

```
> /cp-docs
> /cp-docs .ai/tasks/2026-03-09-1420-rate-limit/
```


## Development

### Structure

```
templates/             # Source templates (edit these)
├── _shared/           # Shared partials: reviewer/fixer dispatch, planning self-checks, research contract
├── cp-review/         # Code review skill + reviewer prompts
├── cp-fix/            # Fix skill + fix agent prompt
├── cp-docs/           # Documentation skill
└── using-codepatrol/  # Planning enhancements

platforms/             # Platform-specific env files
├── claude.env
├── codex.env
├── cursor.env
└── opencode.env

skills/                # Generated output (do not edit)
```

### Developer validation

Local generation commands are for repository development only. End users install through the remote commands above.

```bash
./install.sh build      # Regenerate Claude skills/ from templates
./install.sh validate   # Generate every platform in temporary directories and validate contracts
```

`install.ps1` is maintained for remote Windows installation; local development validation runs through the POSIX build script.

### Template rules

- Templates must be universal — no hardcoded languages or frameworks
- Platform-specific values go in `platforms/*.env`, referenced as `{{VAR_NAME}}`
- Shared content goes in `templates/_shared/`, referenced as `{{@include:path}}` or `{{@platform-include:name}}`
- Skill content stays in English; runtime adapts to the user's language
- Do not add a YAML frontmatter include/preprocessor for duplicated OMP agent output-schema text; keep that duplication explicit

## CI/CD

- **ci.yml** — validates templates, checks build, runs linting on PRs
- **release.yml** — creates GitHub releases from version tags
- **validate-release.yml** — pre-release validation

## Known Limitations

- Tested on macOS only
- OpenCode support is experimental

## License

MIT
