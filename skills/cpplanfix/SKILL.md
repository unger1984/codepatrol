---
name: cpplanfix
description: Fix open plan review findings, mutate tracking fields, and run bounded revalidation
---

# /cpplanfix

Process open findings from `/cpplanreview`.

## Workflow

1. Load the current plan review report
2. Select only `open` findings
3. Decide whether each finding can be auto-fix or needs ask-user guidance
4. Update the plan and report tracking fields
5. Run bounded revalidation on the changed parts

## Fix Policy

Use auto-fix when:
- the resolution is local
- intent is clear
- no meaningful product or architecture trade-off is being decided

Ask the user when:
- multiple valid fixes materially change scope or architecture
- a finding conflicts with accepted constraints
- the report lacks enough context for a safe inference

If `AskUserQuestion` is available, use it. Otherwise ask in chat.

## Bounded Revalidation

Revalidation must confirm that:
- the addressed finding is actually closed
- the updated plan remains consistent with design and workflow rules
- unrelated plan sections were not silently regressed

Do not rerun the entire workflow unless the change requires it. Keep revalidation bounded to the impacted surface.

## Report Mutation

For each finding, update tracking fields such as:
- status
- resolved via
- resolution notes

Preserve the report as the resumable source of truth for subsequent `/cpplanfix` runs.

## User-Facing Examples

- `/cpplanfix`
- `/cpplanfix .ai/tasks/.../reports/2026-03-06-1540-task.plan-review.report.md`

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.

## Completion Criteria

This stage is complete when open findings are resolved or explicitly deferred, and bounded revalidation shows the plan is ready for `/cpexecute`.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
