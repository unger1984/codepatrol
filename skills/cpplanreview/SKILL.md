---
name: cpplanreview
description: Review a plan against project rules, design intent, execution readiness, and docs impact
---

# /cpplanreview

Review the plan artifact before implementation begins.

## Progress Tracking (mandatory)

Before starting review, you MUST create TodoWrite items for each checklist item.
Mark each as `completed` when the check is done.
This provides visual progress to the user.

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

## STOP — Ad Hoc Save Gate (mandatory)

**If there is no active workflow task, you are in ad hoc mode.**

In ad hoc mode you MUST NOT write, create, or save any report file until the user explicitly chooses to save. This is a hard gate — no exceptions, no "I'll ask after saving", no "saving as draft".

Flow:
1. Generate the report content **in conversation only** (do not call Write/Edit/create file).
2. Present the report to the user inline.
3. Ask the user (use `AskUserQuestion` if available) which action to take:
   - **Save report to file** — only then write to `.ai/reports/`
   - **Run /cpplanfix now** — pass results through conversation context, no file
4. Wait for the user's explicit choice before any file I/O.

Violating this gate (saving before asking) is a critical workflow error.

## Output

### Workflow-task reports

Saved automatically (no need to ask) under:
- `.ai/tasks/<task>/reports/YYYY-MM-DD-HHMM-<task-slug>.plan-review.report.md`

### Ad hoc reports

Saved ONLY after user confirms via the save gate above, under:
- `.ai/reports/YYYY-MM-DD-HHMM-<scope>.plan-review.report.md`

### Filename rules

Before generating the filename, run `date +%H%M` to get the current time. Use the real output in the HHMM part of the filename. Never hardcode or guess the time.
Example: `.ai/tasks/2026-03-06-1420-auth-refactor/reports/2026-03-06-1540-auth-refactor.plan-review.report.md`

## Report Format

Structure the report as:

```markdown
## Plan Review Report

### Summary
- Plan: task slug and path
- Critical: N | Important: N | Minor: N
- Assessment: NEEDS_CHANGES | APPROVED | APPROVED_WITH_NOTES

### Critical Issues
1. [CATEGORY] — description
   **Fix:** concrete resolution
   **Status:** open
   **Resolved via:**
   **Resolution notes:**

### Important Issues
(same format)

### Minor Issues
(same format)

### Strengths
What is well structured in the plan.
```

Rules:
- every issue MUST include a Fix field with a concrete resolution — an issue without a Fix is useless
- group by severity: Critical → Important → Minor
- assessment: NEEDS_CHANGES if any Critical, APPROVED_WITH_NOTES if only Important/Minor, APPROVED if no issues

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
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `AskUserQuestion` if available on the current platform.

## Handoff

### Within a workflow task

After the report is saved, the next fix command is `/cpplanfix`. Use the Skill tool to invoke the target skill directly.

### Ad hoc review (no active workflow task)

The save gate above already blocks file I/O. After the user makes their choice:
- If **save** — write the file, then offer `/cpplanfix`.
- If **run /cpplanfix now** — invoke `/cpplanfix` directly, passing findings through conversation context.

## Completion Criteria

This stage is complete when the plan review report exists and all findings are recorded with actionable resolutions.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
