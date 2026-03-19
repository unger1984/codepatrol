## Rules Format (OpenCode)

Rules are stored as `AGENTS.md` files in project directories and `~/.config/opencode/AGENTS.md` for global rules.

### File format

`AGENTS.md` is a plain markdown file with rules organized as sections. No frontmatter — scoping is determined by file placement in the directory tree.

```markdown
# Project Rules

## Code Style
- Use consistent naming: camelCase for variables, PascalCase for types
- ...

## Testing
- Every public function must have tests
- ...
```

OpenCode also supports loading external instructions via `opencode.json`:

```json
{
  "instructions": ["docs/guidelines.md", ".cursor/rules/*.md"]
}
```

### Scoping model

Directory-based scoping:
- **Root `AGENTS.md`** — global rules, apply to all files in the project
- **`src/api/AGENTS.md`** — rules specific to the API layer, apply to all files in `src/api/` and below
- **`tests/AGENTS.md`** — test-specific conventions

OpenCode walks from project root to the current working directory, loading `AGENTS.md` files along the path. Deeper files add to (not replace) rules from parent directories.

### Global rules

Create `~/.config/opencode/AGENTS.md` for rules that apply to all projects. This is useful for personal preferences and AI behavior guidelines.

### Claude Code compatibility

OpenCode supports Claude Code conventions as fallbacks:
- Project: `CLAUDE.md` (used if no `AGENTS.md` exists)
- Global: `~/.claude/CLAUDE.md` (used if no `~/.config/opencode/AGENTS.md` exists)
- Skills: `~/.claude/skills/` directories with `SKILL.md`

### File placement strategy

When placing a new rule, follow this priority:

1. **Scope match first** — if the rule applies to a specific directory subtree, check if `<dir>/AGENTS.md` exists. Add the rule as a section there.
2. **Scoped rule, no existing file** — create `<dir>/AGENTS.md` only if there are 3+ rules for that directory. A single rule goes into the nearest parent `AGENTS.md`.
3. **Global rule** — add as a section in root `AGENTS.md`, grouped by topic.

**Anti-patterns:**
- Creating `AGENTS.md` in every directory — leads to fragmentation
- Putting directory-specific rules in root `AGENTS.md` — defeats scoping
- Duplicating rules across multiple `AGENTS.md` files

### Example

Root `AGENTS.md`:
```markdown
# Project Rules

## Code Style
- Use consistent naming: camelCase for variables, PascalCase for types

## Commits
- Use conventional commits format
```

`src/api/AGENTS.md`:
```markdown
# API Rules

## Endpoints
- All endpoints return JSON with `{ data, error }` envelope
- Use zod schemas for request validation
- Error responses use standard error codes from `src/lib/errors.ts`
```