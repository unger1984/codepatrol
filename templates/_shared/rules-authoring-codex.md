## Rules Format (Codex)

Rules are stored in `AGENTS.md` files — root for global rules, nested in subdirectories for scoped rules.

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

Codex also supports `AGENTS.override.md` which takes priority over `AGENTS.md` in the same directory.

### Scoping model

Scoping is directory-based:
- **Root `AGENTS.md`** — global rules, apply to all files in the project
- **`src/api/AGENTS.md`** — rules specific to the API layer, apply to all files in `src/api/` and below
- **`tests/AGENTS.md`** — test-specific conventions

Codex walks from project root to the current working directory, loading `AGENTS.md` files along the path. Deeper files add to (not replace) rules from parent directories.

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
