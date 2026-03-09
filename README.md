**English** | [Русский](README.ru.md)

# CodePatrol

Project-aware AI skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Codex CLI](https://github.com/openai/codex). Enhances the standard [Superpowers](https://github.com/obra/superpowers) workflow with project rules and documentation awareness.

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
- Approaches are verified against project conventions
- Plans include documentation update steps
- Plans are self-checked against project rules
- Specialized two-pass code review (compliance + quality)

## Skills

| Skill | Purpose |
|-------|---------|
| `using-codepatrol` | Enhances brainstorming and writing-plans with project awareness |
| `/cp-review` | Two-pass code review: compliance (design + plan + rules) then quality (5 specialized reviewers) |
| `/cp-fix` | Process and fix review findings with incremental tracking |

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

### Install from Claude Marketplace

Search for `codepatrol` in Claude Code marketplace.

### Install from latest release

```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- claude
```

### Install from source

```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh claude   # or: ./install.sh codex
```

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


## Development

### Structure

```
templates/             # Source templates (edit these)
├── _shared/           # Shared partials
├── cp-review/         # Code review skill + reviewer prompts
├── cp-fix/            # Fix skill + fix agent prompt
└── using-codepatrol/  # Enhancement definitions

platforms/             # Platform-specific env files
├── claude.env
└── codex.env

skills/                # Generated output (do not edit)
```

### Build

```bash
./install.sh build   # Regenerate skills/ from templates
./install.sh claude  # Generate and install to ~/.claude/skills/
./install.sh codex   # Generate and install to ~/.codex/skills/
```

### Template rules

- Templates must be universal — no hardcoded languages or frameworks
- Platform-specific values go in `platforms/*.env`, referenced as `{{VAR_NAME}}`
- Shared content goes in `templates/_shared/`, referenced as `{{@include:path}}`
- Platform variants use `{{@platform-include:name}}` → `_shared/{name}-{platform}.md`
- Skill content in English; LLM adapts to user's language at runtime

## CI/CD

- **ci.yml** — validates templates, checks build, runs linting on PRs
- **release.yml** — creates GitHub releases from version tags
- **validate-release.yml** — pre-release validation

## Known Limitations

- Tested on macOS only
- Cursor support not yet implemented
- Codex CLI support is experimental

## License

MIT
