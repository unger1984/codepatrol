# CodePatrol

Code review skills for Claude Code and Codex CLI.

## Structure

- `templates/` — source templates with `{{PLACEHOLDER}}` syntax and `{{@include:path}}` directives
- `templates/_shared/` — shared partials included by multiple templates (not a skill)
- `platforms/` — env files with platform-specific values (claude.env, codex.env)
- `skills/` — generated skill files (via `./install.sh build`)
- `.claude-plugin/plugin.json` — plugin manifest
- `.claude-plugin/marketplace.json` — marketplace manifest
- `install.sh` — build and install script

## Build

```bash
./install.sh build   # regenerate skills/ from templates (Claude plugin)
./install.sh claude  # generate and install to ~/.claude/skills/
./install.sh codex   # generate and install to ~/.codex/skills/
```

## Rules

- Templates MUST be universal — no hardcoded languages, frameworks, or project-specific data
- Platform-specific values go in `platforms/*.env`, referenced as `{{VAR_NAME}}` in templates
- Shared content goes in `templates/_shared/`, referenced as `{{@include:_shared/filename.md}}` in templates
- `skills/` is generated output — edit templates, not skills
- All text in skill files in English (LLM adapts to project language via project rules)
- Responses and code comments — in Russian
