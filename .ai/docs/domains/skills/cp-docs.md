# cp-docs

## Purpose

Create and update AI-facing project documentation in `.ai/docs/`.

## When to read

- Creating or updating project documentation
- Understanding task-aware vs ad hoc modes
- Configuring intent resolution for ad hoc requests

## Related docs

- [cp-fix](cp-fix.md) — may trigger docs update after fixes
- [cp-rules](cp-rules.md) — optional next step

---

## Role

**AI project memory maintainer.** Documents stable, reusable project knowledge. Does not transfer temporary reasoning into `.ai/docs/`.

## Mode Detection

| Condition | Mode | Behavior |
|-----------|------|----------|
| Task folder with design/plan exists | Task-aware | Autonomous decision on what/where to document |
| No task context | Ad hoc | Intent Resolution (interactive when unclear) |
| `.ai/docs/` not exists | — | Offer to initialize |

## Ad Hoc Intent Resolution

1. **Parse Intent** — extract action, subject, format hints from user phrase
2. **Read Docs Structure** — read `.ai/docs/README.md` (mandatory)
3. **Scope Decomposition** — single or multiple topics
4. **Target Resolution** — augment existing or create new
5. **Research Decision** — inline (narrow) or subagent (broad)

## Runtime Flow

### Analysis Phase (no writes)
1. Mode detection → brief formation → research → read code → prepare drafts

### Writing Phase (no new reasoning)
2. Apply drafts → validate → present summary

## Documentation Rules

- Document only stable, reusable project knowledge
- Keep README-based navigation intact
- Place in `.ai/docs/domains/` or `.ai/docs/shared/`

## Subagents

| Role | Tier | Purpose |
|------|------|---------|
| Research subagent | Per model-policy | Broad-scope research |

## Change Impact

- Changing doc file format affects all existing docs
- Changing validation pass affects completeness criteria
