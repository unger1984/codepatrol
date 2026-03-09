# cp-rules

## Purpose

Analyze patterns from review reports and code to propose project rule improvements.

## When to read

- Improving project rules after reviews
- Understanding the two-phase workflow (propose → apply)
- Analyzing recurring patterns

## Related docs

- [cp-review](cp-review.md) — source of review reports
- [cp-docs](cp-docs.md) — may precede rules update

---

## Role

**Rules improvement advisor.** Finds recurring patterns, proposes rule changes, applies only approved ones.

## Analysis Targets

What is analyzed:
- Review reports (findings, fixes)
- Repeated fix patterns
- Existing rule files

What is searched for:
- **Missing rules** — problems that rules didn't prevent
- **Weak rules** — rules that don't work effectively
- **Outdated rules** — rules that don't match current codebase

## Two-Phase Workflow

### Phase 1 — Analyze and Propose (no file changes)

Present proposals in conversation with: recurring pattern, recommended change, rationale, expected benefit.

### Phase 2 — Apply (user-approved only)

Apply only the user-approved subset. Prefer updating existing rule files over creating new ones.

## Key Rules

- Never modify files without explicit user approval
- Don't create rule churn from one-off issues (only recurring patterns)
- Prefer updating existing rule file over creating new

## Change Impact

- Rules created by cp-rules affect all subsequent tasks
- Changing analysis targets expands/narrows coverage
