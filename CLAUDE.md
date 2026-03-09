# CodePatrol

Project-aware AI skills for Claude Code and Codex CLI. Enhances Superpowers workflow with project rules and documentation awareness.

## Structure

- `templates/` — source templates with `{{PLACEHOLDER}}` syntax, `{{@include:path}}` and `{{@platform-include:name}}` directives
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
- Platform-variant partials use `{{@platform-include:name}}` — resolves to `_shared/{name}-{platform}.md` (e.g., `rules-authoring-claude.md`)
- `skills/` is generated output — edit templates, not skills
- Skill file content (templates/ and skills/) — in English. LLM adapts to the user's language via project rules at runtime.
- Developer communication (responses, code comments, commit messages) — in Russian
- After editing any file in `templates/`, run `./install.sh build` to regenerate `skills/`
- After any skill or behavior change, check and update `README.md`, `README.ru.md`, and `.ai/docs/` if affected — documentation updates are part of the change
