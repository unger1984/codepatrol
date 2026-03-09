## Rules Format (Cursor)

Rules are stored as individual `.mdc` files in `.cursor/rules/`. Cursor also supports `AGENTS.md` files as an alternative format.

### File format

Each `.mdc` rule file uses YAML frontmatter to control when it is applied:

```yaml
---
description: Short description of what this rule covers
globs: ["src/api/**/*.ts", "src/api/**/*.test.ts"]
alwaysApply: false
---

Rule content in markdown.
```

**Frontmatter fields:**
- `description` — shown in rule listings, used by Agent to decide relevance when `alwaysApply` is `false`
- `globs` — file patterns this rule applies to (activated when matching files are in context)
- `alwaysApply` — if `true`, rule is included in every session regardless of context

### Application modes

Cursor supports 4 modes that determine when a rule is loaded:

1. **Always Apply** — `alwaysApply: true`. Included in every chat and Composer session unconditionally.
2. **Apply Intelligently** — `alwaysApply: false` with `description` set. Agent reads the description and decides whether to include the rule based on current context.
3. **Apply to Specific Files** — `globs` set. Activated automatically when files matching the glob pattern are in context.
4. **Apply Manually** — no `alwaysApply`, no `globs`, no `description`. User must explicitly reference the rule via `@rule-name` in chat.

**When to use each mode:**
- **Always Apply** — universal rules: naming, commit messages, language policy, general codestyle
- **Apply Intelligently** — domain rules that apply situationally: API conventions, testing philosophy, architecture decisions
- **Apply to Specific Files** — rules for specific areas: file-type conventions, directory-scoped patterns, migration policy
- **Apply Manually** — rarely used workflows or reference material the user invokes on demand

### Rule priority

When rules conflict, Cursor resolves by source priority:

1. **Team Rules** (highest) — shared via version control, apply to all team members
2. **Project Rules** — `.cursor/rules/` in the project directory
3. **User Rules** (lowest) — personal rules in global Cursor settings

### File placement strategy

When placing a new rule, follow this priority:

1. **Scope match first** — find an existing `.mdc` file whose `globs` overlap with the new rule's scope. Add the rule there, expanding `globs` if needed.
2. **Scoped rule, no matching file** — create a new `.mdc` file with appropriate `globs`. Name it after the scope area (e.g. `api-conventions.mdc`, `test-patterns.mdc`).
3. **Global rule, thematic match** — find an existing `alwaysApply: true` file on the same topic. Add the rule there.
4. **Global rule, no thematic match** — if 3+ related rules justify a new file, create one. A single rule goes into the closest thematic file.

**Anti-patterns:**
- One file per rule — leads to file sprawl
- All rules in one file — makes scoping impossible
- Mixing unrelated scoped rules in one file — confusing `globs`
- Using "Apply Manually" when "Apply Intelligently" would work — rules that require manual invocation are easy to forget

### Alternative: AGENTS.md

Cursor also supports `AGENTS.md` as a plain markdown format (no frontmatter, no scoping). Use `.mdc` files for granular control; use `AGENTS.md` only for broad project-wide rules that don't need conditional application.

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
