### Draft Creation

Drafts are lightweight task sketches stored in `.ai/drafts/`. They capture enough context for `/cp-idea` to start a full task later. Drafts can be created by any skill — fixers defer findings, `/cp-idea` saves side-topics or early-stage ideas.

#### Creating a draft

1. Check `.ai/drafts/` for existing drafts that cover the same scope (same file + same area, or same concept). If a matching draft exists, show it to the user and ask whether to update it or create a new one.
2. Run `date +%Y-%m-%d-%H%M` to get the current timestamp. Never hardcode or guess the time.
3. Create the draft file at `.ai/drafts/<YYYY-MM-DD-HHMM>-<slug>.draft.md`. Use `mkdir -p` for the directory.
4. If created from a fixer — update the report finding: set `**Status:** deferred` and add `**Draft:** .ai/drafts/<YYYY-MM-DD-HHMM>-<slug>.draft.md`.

#### Draft file format

```markdown
# Draft: <title>

**Status:** open
**Created:** <YYYY-MM-DD> by <source-skill>

## Origin

- Source: <source-skill> (<context — e.g. report path, task path, or "ad hoc">)
- Finding: #N [Severity] — short description (if from a fixer)
- Parent task: <task-directory-path> (if created during another task's workflow)

## Problem

<what needs to be done, in which area/module, why it matters — enough context for cp-idea to start>

## Context

<clarification results, research findings, approach ideas — whatever was gathered before deferral>

## Hints

<suggestions for future work — what to consider, dependencies, related areas, possible approaches>
```

Fill only the sections that have content. For fixer drafts, `## Context` may be minimal. For `/cp-idea` drafts, it may include clarification and approach discussion results.

#### Slug rules

The slug should be short and descriptive, derived from the subject. Example: `refactor-auth-middleware`, `extract-video-series-utils`.

#### Duplicate check

Before creating a draft, search `.ai/drafts/` for files with `**Status:** open`. Compare:
- same file or module mentioned in `## Problem`
- same concept or description

If a potential duplicate is found, show it to the user and ask:
- **Update existing draft** — append the new context
- **Create new draft** — the topics are different enough to warrant a separate draft
- **Skip draft creation** — do not create a draft

Do not create duplicate drafts silently.
