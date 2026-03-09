
# Design: Cursor Platform Support

## Goal

Add Cursor IDE as a third supported platform in CodePatrol, alongside Claude Code and Codex CLI.

## New Files

### `platforms/cursor.env`

Platform variables adapted for Cursor Agent tools:

| Variable | Value |
|----------|-------|
| `ASK_USER` | Ask the user a question using the built-in Ask Questions tool. You can continue other work while waiting for a response. |
| `SKILLS_DIR` | `~/.cursor/skills` |
| `RULES_SOURCE` | `.cursor/rules/*.mdc` files with frontmatter (description, globs, alwaysApply) and `AGENTS.md` |
| `DISPATCH_AGENT` | Define subagents as `.md` files in `.cursor/agents/` with YAML frontmatter (name, description, model, background). Use `background: true` for parallel execution. |
| `PROGRESS_TOOL` | Checkpoints (automatic snapshots). No dedicated todo/checklist tool. |
| `FILE_DISCOVERY` | Use Semantic Search for meaning-based lookups and Search Files for name/pattern matching. Do not fall back to shell commands unless no dedicated tool is available. |
| `WEB_RESEARCH` | Use Web tool for search queries. Use Browser tool for interactive page inspection. Prefer official documentation over blog posts. |
| `DISPATCH_RESEARCHER` | Define a research subagent in `.cursor/agents/` with `background: true`, dispatch by name or let Agent auto-delegate based on description. |

### `templates/_shared/aliases-cursor.md`

Same as Claude (no built-in `/review` conflict in Cursor):

```
/review → /cp-review
/fix → /cp-fix
/docs → /cp-docs
```

### `templates/_shared/rules-authoring-cursor.md`

Cursor-specific rules format documentation:
- MDC format (`.mdc` files) with YAML frontmatter: `description`, `globs`, `alwaysApply`
- 4 application modes: Always Apply, Apply Intelligently, Apply to Specific Files, Apply Manually
- File placement strategy adapted for `.cursor/rules/`
- `AGENTS.md` as alternative (also supported by Cursor)

## Changes to Existing Files

### `install.sh`

- New case `cursor`: generate with `cursor.env`, install to `~/.cursor/skills/`, clean old skills
- Update `usage()` to include `cursor` command

### `.claude/rules/skill-authoring.md`

New rule in Change checklist — cross-platform compatibility:
- When editing templates or shared partials, verify impact on ALL supported platforms (Claude, Codex, Cursor)
- If adding `{{PLACEHOLDER}}` — ensure it is defined in all `platforms/*.env`
- If adding `{{@platform-include:name}}` — create a partial for every platform

### Documentation

- `CLAUDE.md` — add `cursor` to Build section
- `README.md` / `README.ru.md` — mention Cursor support
- `.ai/docs/shared/architecture.md` — add cursor to variables table, platform list, build commands
