---
name: cpplanreview
description: Review a plan against project rules, design intent, execution readiness, and docs impact
---

# /cpplanreview

Review the plan artifact before implementation begins.

## Scope

Review the current `plan.md` against:
- project rules
- approved design
- workflow execution model
- verification expectations
- documentation impact

This is a plan review, not code review.

## Required Inputs

- the current `plan.md`
- the current `workflow.md`
- the approved `design.md` when present
- relevant project rules from ``.claude/rules/*.md` and `CLAUDE.md``
- targeted project docs starting from `.ai/docs/README.md`

## Review Checklist

- Is the plan consistent with the approved design?
- Does the plan cover all required implementation steps?
- Is the execution model safe and realistic?
- Are verification steps explicit and sufficient?
- Does the plan account for docs, install, release, and operational impact when relevant?
- Does the plan avoid scope creep?

## Output

Produce a normalized report with findings that include:
- severity
- finding type
- recommended resolution
- status
- resolution notes placeholder

Save workflow-task reports under:
- `.ai/tasks/<task>/reports/<timestamp>-<task-slug>.plan-review.report.md`

If the review is ad hoc and not task-scoped, save under `.ai/reports/`.

## Interaction Rules

- Keep internal instructions in English
- Use only new command names in user-facing examples, such as `/cpplanreview` and `/cpplanfix`
- If scope or artifact selection is ambiguous, ask before proceeding

## Completion Criteria

This stage is complete when the plan review report exists and all findings are recorded with actionable resolutions.
