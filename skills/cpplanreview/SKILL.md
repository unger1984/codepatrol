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
- targeted project docs starting from `.ai/docs/README.md` if it exists

## Review Checklist

- Is the plan consistent with the approved design?
- Does the plan cover all required implementation steps?
- Is the execution model safe and realistic?
- Is the plan executable by the specified execution model? If a weaker model is specified, is the granularity adapted?
- Can the plan be improved to reduce context per implementer or enable safer parallelization?
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

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.

## Completion Criteria

This stage is complete when the plan review report exists and all findings are recorded with actionable resolutions.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
