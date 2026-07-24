# AGENTS.md — CodePatrol Developer Guide

This file provides guidelines for AI agents working in this repository.
дава
---

## Project Overview

CodePatrol generates platform-specific skill files for AI coding assistants (Claude Code, Codex CLI, Cursor) from Markdown templates. It extends the Superpowers skill chain with project-aware rules and documentation.

**Key directories:**
- `templates/` — Source templates (edit here first)
- `platforms/` — Platform-specific values (`.env` files)
- `skills/` — Generated output (do not hand-edit)
- `.claude-plugin/` — Plugin manifests
- `.github/workflows/` — CI/CD pipelines

---

## Build, Install & Validation Commands

### Build Commands
```bash
./install.sh build   # Regenerate skills/ from templates (claude platform)
./install.sh claude # Generate + install to ~/.claude/skills/
./install.sh codex  # Generate + install to ~/.codex/skills/
./install.sh cursor # Generate + install to ~/.cursor/skills/
./install.sh opencode # Generate + install to ~/.config/opencode/skills/
```

### Manual Validation
1. `./install.sh build` — verify no errors
2. `git diff skills/` — should show empty diff (up-to-date)
3. `./install.sh <platform>` — verify installation
4. Check generated files in `skills/`

### CI Checks (on every PR)
```bash
# Equivalent to CI validation:
./install.sh build && git diff --quiet skills/
test -f skills/using-codepatrol/SKILL.md
test -f skills/cp-review/codestyle-reviewer.md
# ... etc for all required files
```

---

## Template Authoring Guidelines

### File Structure
- Templates use `{{PLACEHOLDER}}` syntax for variable substitution
- Include shared content: `{{@include:relative/path.md}}`
- Platform variants: `{{@platform-include:filename}}` → `_shared/filename-{platform}.md`
- Environment variables in `platforms/{platform}.env`

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Skill directories | lowercase, cp-prefix | `cp-review`, `cp-fix` |
| Shared partials | kebab-case | `rules-authoring-claude.md` |
| Env variables | UPPER_SNAKE_CASE | `DISPATCH_AGENT`, `SKILLS_DIR` |
| Placeholders | `{{UPPER_SNAKE_CASE}}` | `{{AGENT_NAME}}` |

### Content Style
- **Language:** English in all skill files; LLM adapts to user's language at runtime
- **Markdown:** Concise, clear section headers; use bullet lists over paragraphs
- **Scope:** Platform-agnostic templates; differences only in `platforms/*.env`
- **No hardcoding:** Avoid language/framework specifics unless necessary

### Template Syntax Examples
```
# Variable substitution
{{@include:_shared/researcher.md}}

# Platform-specific include (becomes _shared/model-policy-claude.md)
{{@platform-include:model-policy}}

# Empty value → removes entire line
{{# If value is empty, the line containing {{EMPTY_VAR}} is removed #}}
```

---

## Coding Style & Conventions

### Shell Scripts (install.sh)
- POSIX-compatible (`bash` with `set -e` for error handling)
- Use `$(command)` for command substitution (not backticks)
- Functions with local variables (`local var=value`)
- Proper quoting: `"$variable"` not `$variable`
- Keep scripts executable (`chmod +x`)

### Markdown Files
- ATX headers (`# ## ###`) consistently
- One blank line between sections
- Code blocks with language hints: ` ```bash `, ` ```yaml `
- Keep lines under 120 characters
- Tables for structured data

### Git Conventions
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`)
- **Branches:** Descriptive names (`feat/cp-review-v2`)
- **PRs:** Include purpose, before/after examples, verification commands

---

## Project-Specific Rules

### What NOT to Do
- Do not hand-edit files in `skills/` (regenerated on build)
- Do not commit secrets to `platforms/*.env`
- Do not mix unrelated scoped rules in one file
- Do not create one file per rule (file sprawl)

### What to Do
- Edit templates first, then run `./install.sh build`
- Use `_shared/` for content shared across skills
- Group related rules by scope (API, tests, security)
- Review generated output before committing

---

## Troubleshooting

### "platform include file not found" error
- Check `_shared/{name}-{platform}.md` exists for each `{{@platform-include:name}}`
- Platforms: `claude`, `codex`, `cursor`

### Leftover `{{PLACEHOLDERS}}` in generated files
- Ensure variable is defined in corresponding `platforms/{platform}.env`
- Empty values remove the entire line

### skills/ shows changes after build
- Run `./install.sh build` and commit the changes
- Templates were edited but not regenerated

---

## Security Notes

- `platforms/*.env` should contain only generic values (no API keys, tokens)
- Generated files in `skills/` may contain sensitive paths — review before publishing
- Shell scripts should handle errors gracefully

---

## Additional Resources

- [README.md](README.md) — Project overview and quick start
- [Superpowers skills](https://github.com/obra/superpowers) — Base workflow this extends
- [.github/workflows/ci.yml](../.github/workflows/ci.yml) — CI validation
