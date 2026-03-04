**English** | [Русский](README.ru.md)

# CodePatrol — Code Review Skills for AI Agents

## Table of Contents

- [Skills](#skills)
  - [/code-review](#code-review)
  - [/code-review-fix](#code-review-fix)
- [Installation](#installation)
- [Requirements](#requirements)
- [Development](#development)
- [Known limitations](#known-limitations)
- [License](#license)

A set of code review skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Codex CLI](https://github.com/openai/codex).

These skills don't just run generic linting — they review code against **your project's rules**: codestyle, architecture, naming conventions, allowed patterns, and design decisions. Each review launches 4 specialized subagents in parallel, covering different domains. The result is a structured report with concrete, actionable fix suggestions.

> **The quality of the review is only as good as your project rules.** Skills check code for compliance with conventions you've defined in your rule files. Well-written, specific rules (codestyle, architecture, naming, forbidden patterns) produce detailed, useful reviews. Vague or missing rules lead to shallow, generic output. Invest time in your rules — that's what makes this tool powerful.

**Where rules are read from:**

- **Claude Code**: `.claude/rules/*.md`, `CLAUDE.md`
- **Codex CLI**: `AGENTS.md` (root and nested)

## Skills

### `/code-review`

Parallel review dispatcher. Launches 4 specialized subagents simultaneously, each checking code against its own checklist:

- **Codestyle** — naming, formatting, prohibited patterns, project conventions
- **Architecture** — SOLID, layering, dependency inversion, separation of concerns
- **Security** — OWASP top 10, input validation, auth, data exposure
- **Testing** — coverage, AAA pattern, edge cases, test quality

Supports multiple review scopes:

| Flag | Scope |
|------|-------|
| *(none)* | Committed diff: current branch vs main |
| `--uncommitted` | Staged + unstaged + untracked changes |
| `--pr [number]` | Pull request diff |
| `--all` | All project files |
| `--plan <path>` | Review a design document |
| `--impl <path>` | Review code implementing a plan |
| `<paths>` | Specific files or directories |

Also understands natural language — no need to memorize flags:

| You say | What happens |
|---------|--------------|
| `/code-review` | Committed diff vs main |
| `/code-review uncommitted code` | Uncommitted changes |
| `/code-review review the PR` | Current branch PR diff |
| `/code-review check the plan docs/plans/auth.md` | Reviews the design document |
| `/code-review apps/api/` | Reviews files in the directory |

Output: a structured Markdown report grouped by severity (Critical > Important > Minor), with concrete fix suggestions for every issue found.

### `/code-review-fix`

Interactive fix processor for code review reports. Works through each issue one by one:

1. Shows the issue with context
2. Proposes fix options with trade-offs (pros/cons)
3. User picks an option
4. Dispatches a subagent to apply the fix
5. Updates the report file with status (DONE / SKIP / CHANGED)

Can process a report from a file or directly from conversation context after `/code-review`.

## Installation

### Quick install (from latest release)

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install-remote.sh | bash

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install-remote.sh | bash -s codex
```

### Claude Code (as a plugin via marketplace)

```
/plugin marketplace add unger1984/codepatrol
/plugin install codepatrol@unger1984/codepatrol
```

Skills will be available as `/codepatrol:code-review` and `/codepatrol:code-review-fix`.

### From source

```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh claude  # or: ./install.sh codex
```

## Requirements

- **git** — required for diff-based review scopes
- **gh** (GitHub CLI) — required for `--pr` flag
- No external MCP servers or plugins needed — skills use only built-in agent tools

## Development

The repository uses a template-based approach to maintain a single source of truth for both platforms.

```
templates/                        # Source templates with {{PLACEHOLDER}}s
platforms/                        # Platform-specific variable files
plugins/codepatrol/               # Plugin (installed via marketplace)
  skills/                         # Generated skill files (plugins/codepatrol/skills/)
  .claude-plugin/plugin.json      # Plugin manifest
.claude-plugin/marketplace.json   # Marketplace manifest
install.sh                        # Build & install script
```

```bash
./install.sh build   # Regenerate plugin skills from templates
./install.sh codex   # Generate and install for Codex
./install.sh claude  # Generate and install locally for Claude
```

## Known limitations

- Skills have only been tested on **macOS**. They may work on Linux and Windows, but haven't been verified — contributions and bug reports are welcome.
- **Cursor** is not yet supported. The skill format and agent dispatch mechanism need to be adapted for Cursor's architecture.

## License

MIT
