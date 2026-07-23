# using-codepatrol

## Table of Contents
- [Purpose](#purpose)
- [When to read](#when-to-read)
- [Related docs](#related-docs)
- [Activation](#activation)
- [Enhancements](#enhancements)
  - [brainstorming](#brainstorming)
  - [writing-plans](#writing-plans)
- [Artifact Rules](#artifact-rules)
- [Related Skills](#related-skills)
- [Change Impact](#change-impact)

## Purpose

Enhances Superpowers brainstorming and writing-plans with mandatory project rules, relevant existing
documentation, cited prepared planning context, delegated self-checks, a single task-artifact location, and a
direct route for non-engineering creative ideation that must not spawn engineering artifacts.

## When to read

- Changing planning enhancements or artifact storage
- Understanding when Superpowers planning should start
- Handling non-engineering creative ideation requests without loading engineering planning context
- Diagnosing design or plan artifact placement

## Related docs

- [Skills Reference](../skills-reference.md) — all skills overview

---

## Activation

The skill loads before `superpowers:brainstorming` or `superpowers:writing-plans` when the user explicitly
requests brainstorming, design, or a plan, or when a pre-edit decision requires user approval.

It must not activate for clear direct work: localized changes, known-cause bug fixes, mechanical refactors,
review, documentation, investigation, or execution of an approved plan. Uncertainty is resolved in favor of
direct implementation; planning starts later only if a real design fork emerges.

For non-engineering creative ideation, the skill still routes through `superpowers:brainstorming`, but only for
the idea conversation itself: no design.md, no plan.md, no `.ai/tasks/` artifact, no `.ai/docs` sweep, and no
engineering implementation checklist unless the request later becomes a software-system change.

## Enhancements

### brainstorming

1. Reads applicable project rules and relevant existing `.ai/docs`.
2. Checks proposed approaches against rules and conventions.
3. Builds one cited prepared planning context: artifact path/type, explicit requirements, only applicable rule/doc excerpts, approved-design excerpts for plans, and missing-context blockers.
4. Uses that context to keep artifact-integrity checks narrow and to give plan/compliance checks only the cited subsets they need.
5. Allows one fast read-only preparer only for broad context assembled from multiple source sets.
6. Corrects non-material findings through the matching fixer tier before the user-review gate.
7. Saves the only design artifact at `.ai/tasks/YYYY-MM-DD-HHMM-slug/design.md`.

Absent `.ai/docs` is a no-op. The skill does not ask to initialize docs or add such work to a plan solely because docs are absent.

### writing-plans

1. Reads project rules, relevant existing docs, and the approved current-task design.
2. Includes a documentation update step only when existing docs cover changed architecture, APIs, data structures, or conventions.
3. Reuses the same cited prepared planning context pattern for artifact integrity, plan completeness/dependencies/verification, and rules/docs/design compliance checks.
4. Corrects non-material findings through the matching fixer tier; a correction that changes an approved design decision is presented to the user instead.
5. Saves the only plan artifact beside its design at `.ai/tasks/YYYY-MM-DD-HHMM-slug/plan.md`.

A design is current only if it was approved in the same session or its path was explicitly supplied. The skill never searches for the most recent design lacking a plan.


## Artifact Rules

No design or plan copy is written to Superpowers default directories. If a plan refers to an existing design
whose path is unknown, ask for the path. If no design is in scope, create a new task folder when saving the
plan.

## Related Skills

`/cp-review`, `/cp-fix`, and `/cp-docs` remain explicit workflows. Short aliases such as `/fix` and `/docs`
are independent convenience mappings, not planning triggers.

## Change Impact

- Changing planning enhancements or artifact paths: update this document and the template.
- Adding a related CodePatrol skill: update its own documentation; do not add a planning route here.
