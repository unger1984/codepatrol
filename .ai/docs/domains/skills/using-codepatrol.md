# using-codepatrol

## Purpose

Enhances the Superpowers workflow (brainstorming, writing-plans) with project rules and documentation awareness. Routes review, fix, docs, and rules tasks to CodePatrol skills.

## When to read

- Understanding how project awareness is injected into brainstorming and writing-plans
- Adding new enhancements to the workflow
- Understanding skill routing

## Related docs

- [Skills Reference](../skills-reference.md) — all skills overview

---

## Role

Enhancement layer for Superpowers workflow + router for CodePatrol-specific skills.

## Enhancements

### brainstorming enhancement

Applied at three points in the standard brainstorming flow:

1. **Explore project context** — reads `.claude/rules/`, `CLAUDE.md`, `.ai/docs/` (relevant parts), recent commits
2. **Propose approaches** — verifies each approach against project rules and conventions
3. **Present design** — references relevant project rules in the design

The design artifact is redirected to `.ai/tasks/YYYY-MM-DD-HHMM-slug/design.md` — a location override applied regardless of the standard flow's default (as of Superpowers 6.1.x, `docs/superpowers/specs/`). Enhancements are deltas layered on top: steps CodePatrol does not override (visual companion offer, spec self-review, user-review gate) are left intact, and the flow is not re-narrated or re-ordered.

### writing-plans enhancement

Applied before, during, and after plan writing:

1. **Before** — reads project rules, `.ai/docs/` (relevant parts), and design file
2. **During** — includes `.ai/docs` update step if task affects documented architecture/APIs
3. **After** — a project-specific self-check (rules, docs, design file) layered on top of the standard flow's own generic self-review — not a replacement

The plan artifact is redirected to `.ai/tasks/YYYY-MM-DD-HHMM-slug/plan.md` (override of the standard default, as of Superpowers 6.1.x `docs/superpowers/plans/`).

## Routing Table

| Intent | Skill |
|--------|-------|
| New task / idea / design | brainstorming (superpowers) + enhancements |
| Write implementation plan | writing-plans (superpowers) + enhancements |
| Implement from plan | executing-plans / subagent-driven-development (superpowers) |
| Code review | `/cp-review` |
| Fix review findings | `/cp-fix` |
| Documentation | `/cp-docs` |
| Improve rules | `/cp-rules` |

## Dependencies

None. This is an entry-point skill loaded at session start.

## Change Impact

- Adding a new enhancement point: update the relevant enhancement section
- Adding a new CodePatrol skill: update routing table
