# Skills Reference

## Purpose

Reference for all CodePatrol skills — purpose, inputs/outputs, and how they integrate with Superpowers.

## When to read

- Looking up what a specific skill does
- Understanding how CodePatrol integrates with Superpowers workflow
- Adding or modifying a skill

## Scope

All skills in `templates/`. For build mechanics see [Architecture](../shared/architecture.md).

## Related docs

- [Review System](review-system.md) — detailed review mechanics
- [Architecture](../shared/architecture.md) — template system

---

## Integration Model

CodePatrol **enhances** the Superpowers workflow chain instead of replacing it:

```mermaid
flowchart TD
    BS["brainstorming (superpowers)"] -->|"+ project rules, docs"| WP["writing-plans (superpowers)"]
    WP -->|"+ project rules, docs, self-check"| EP["executing-plans (superpowers)"]
    EP -->|"user decides"| CR["/cp-review"]
    CR -->|"if findings"| CF["/cp-fix"]
```

`using-codepatrol` defines the enhancements that are applied to brainstorming and writing-plans.

## Skills Overview

| Skill | Purpose | Detailed doc |
|-------|---------|-------------|
| [using-codepatrol](skills/using-codepatrol.md) | Enhancements for brainstorming and writing-plans | [details](skills/using-codepatrol.md) |
| [cp-review](skills/cp-review.md) | Two-pass code review (compliance + quality) | [details](skills/cp-review.md) |
| [cp-fix](skills/cp-fix.md) | Fix code review findings | [details](skills/cp-fix.md) |

## Task Artifacts

All task artifacts are stored in `.ai/tasks/`:

```
.ai/tasks/YYYY-MM-DD-HHMM-slug/
├── design.md    — approved design (saved by brainstorming)
├── plan.md      — implementation plan (saved by writing-plans)
└── review.md    — code review report (saved by /cp-review)
```

Ad-hoc review reports (no task context): `.ai/reports/YYYY-MM-DD-HHMM-<scope>.review.md`

## Shared Mechanics

| Mechanic | Used by | Description |
|----------|---------|-------------|
| Progress tracking | cp-review, cp-fix | Mandatory — progress items before starting work |
| Incremental report mutation | cp-fix | Report updated after each finding (not batched) |
| Ad hoc save gate | cp-review, cp-fix | File not saved without explicit user approval |
| Model policy | cp-review | Subagent tiers: fast/default/powerful + ceiling rule |
| Bounded revalidation | cp-fix | Revalidation only of impacted sections |
| Blocker policy | All skills | Stop and ask on conflicts, ambiguity, verification failure |

## Change Impact

- Adding a new skill: create template dir, add SKILL.md with frontmatter, rebuild, update using-codepatrol if routing needed
- Changing report format: impacts cp-fix parsing
- Modifying enhancement definitions: update using-codepatrol template
