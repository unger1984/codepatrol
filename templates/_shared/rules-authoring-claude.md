## Rules Format (Claude Code)

Rules are stored as individual `.md` files in `.claude/rules/` and as `CLAUDE.md` files (root and nested).

### File format

Each rule file supports optional YAML frontmatter:

```yaml
---
description: Short description of what this rule covers
globs: ["src/api/**/*.ts", "src/api/**/*.test.ts"]
alwaysApply: false
---

Rule content in markdown.
```

**Frontmatter fields:**
- `description` — shown in rule listings, helps agents decide relevance
- `globs` — file patterns this rule applies to (only loaded when matching files are in context)
- `alwaysApply` — if `true`, rule is always loaded regardless of file context

**When to use scoping:**
- `alwaysApply: true` — universal rules: naming, commit messages, language policy, general codestyle
- `globs` without `alwaysApply` — rules for specific areas: API conventions, test patterns, migration policy
- No frontmatter — treated as always-apply

### File placement strategy

When placing a new rule, follow this priority:

1. **Scope match first** — find an existing file whose `globs` overlap with the new rule's scope. Add the rule there, expanding `globs` if needed.
2. **Scoped rule, no matching file** — create a new file with appropriate `globs`. Name it after the scope area (e.g. `api-conventions.md`, `test-patterns.md`).
3. **Global rule, thematic match** — find an existing `alwaysApply: true` file on the same topic. Add the rule there.
4. **Global rule, no thematic match** — if 3+ related rules justify a new file, create one. A single rule goes into the closest thematic file.

**Anti-patterns:**
- One file per rule — leads to file sprawl
- All rules in one file — makes scoping impossible
- Mixing unrelated scoped rules in one file — confusing `globs`

### Example

```yaml
---
description: API endpoint conventions
globs: ["src/api/**", "src/routes/**"]
alwaysApply: false
---

- All endpoints return JSON with `{ data, error }` envelope
- Use zod schemas for request validation
- Error responses use standard error codes from `src/lib/errors.ts`
```
