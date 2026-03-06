---
name: cpplanfix
description: Fix open plan review findings, mutate tracking fields, and run bounded revalidation
---

# /cpplanfix

Process open findings from `/cpplanreview`.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create {{PROGRESS_TOOL}} items for each open finding.
Mark each as `in_progress` when working on it and `completed` when revalidation confirms the fix.
This provides visual progress to the user.

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

If `{{ASK_USER}}` is available, use it. Otherwise ask in chat.

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
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

## Completion Criteria

### Within a workflow task

This stage is complete when open findings are resolved or explicitly deferred, and bounded revalidation shows the plan is ready for `/cpexecute`.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.

### Ad hoc fix (no active workflow task)

After all fixes and bounded revalidation, the work is complete. No `/cpexecute` handoff is required.

If the source report was a saved file, update its tracking fields as usual.

If findings were passed through conversation context (no saved file), ask the user (use `{{ASK_USER}}` if available) after all fixes are done:

1. **Save report to file** — save the completed report with all resolution tracking fields to `.ai/reports/`
2. **Do not save** — findings and their resolutions stay only in the current conversation

Do not save silently — always present the options and wait for the user's choice.
