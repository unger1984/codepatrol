# CodePatrol

Code review skills for Claude Code and Codex CLI.

## Structure

- `templates/` — source templates with `{{PLACEHOLDER}}` syntax
- `platforms/` — env files with platform-specific values (claude.env, codex.env)
- `plugins/codepatrol/` — plugin directory (installed via marketplace)
  - `skills/` — generated skill files at `plugins/codepatrol/skills/` (via `./install.sh build`)
  - `.claude-plugin/plugin.json` — plugin manifest
- `.claude-plugin/marketplace.json` — marketplace manifest
- `install.sh` — build and install script

## Build

```bash
./install.sh build   # regenerate plugins/codepatrol/skills from templates (Claude plugin)
./install.sh claude  # generate and install to ~/.claude/skills/
./install.sh codex   # generate and install to ~/.codex/skills/
```

## Rules

- Templates MUST be universal — no hardcoded languages, frameworks, or project-specific data
- Platform-specific values go in `platforms/*.env`, referenced as `{{VAR_NAME}}` in templates
- `plugins/codepatrol/skills/` is generated output — edit templates, not skills
- All text in skill files in English (LLM adapts to project language via project rules)
- Responses and code comments — in Russian
