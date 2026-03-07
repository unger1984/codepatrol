---
name: cp-plan-review
description: Review an implementation plan for correctness, compliance, and readiness
---

# /cp-plan-review

Review the plan artifact before implementation begins.

## Progress Tracking (mandatory)

Before starting review, you MUST create {{PROGRESS_TOOL}} items for each checklist item.
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

- the current `plan.md` (master file with batch index if batched)
- all `plan-batch-NN.md` files when present
- the current `workflow.md`
- the approved `design.md` when present
- relevant project rules from `{{RULES_SOURCE}}`
- targeted project docs starting from `.ai/docs/README.md` if it exists

**Batched plans:** when a plan uses batch files, review each batch independently but also verify cross-batch consistency (dependency graph, shared contracts, no scope gaps between batches).

## Execution Model

- **simple plans** (few checklist items, narrow scope) — the orchestrator runs all checks directly
- **medium and large plans** — the orchestrator may dispatch checklist groups to subagents:
  - design consistency and scope → default tier
  - execution readiness and verification → default tier
  - docs/operational impact → fast tier
- {{DISPATCH_AGENT}}
- all findings from subagents must be normalized into one report

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

## Review Checklist

- Is the plan consistent with the approved design?
- Does the plan cover all required implementation steps?
- Is the execution model safe and realistic?
- Is the plan executable by the specified execution model? If a weaker model is specified, is the granularity adapted?
- Can the plan be improved to reduce context per implementer or enable safer parallelization?
- If batched: are batch boundaries logical? Are cross-batch dependencies explicit? Are there scope gaps or overlaps between batches?
- Does the plan granularity match the specified executor tier?
- Are verification steps explicit and sufficient?
- Does the plan account for docs, install, release, and operational impact when relevant?
- Does the plan avoid scope creep?

## STOP — Ad Hoc Save Gate (mandatory)

**If there is no active workflow task, you are in ad hoc mode.**

In ad hoc mode you MUST NOT write, create, or save any report file until the user explicitly chooses to save. This is a hard gate — no exceptions, no "I'll ask after saving", no "saving as draft".

Flow:
1. Generate the report content **in conversation only** (do not call Write/Edit/create file).
2. Present the report to the user inline.
3. Ask the user (use `{{ASK_USER}}` if available) which action to take:
   - **Save report to file** — only then write to `.ai/reports/`
   - **Run /cp-plan-fix now** — pass results through conversation context, no file
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

Use `mkdir -p` when creating report directories. This is idempotent — do not check existence separately or ask the user for permission to create `.ai/` directories.

## Report Format

The first line of every report file is reserved for processing metadata (e.g. `<!-- cp-rules: processed YYYY-MM-DD -->`). When creating a new report, leave the first line empty. When editing an existing report, never modify or remove the first line.

Structure the report as:

```markdown

## Plan Review Report

### Summary
- Plan: task slug and path
- Critical: N | Important: N | Minor: N
- Assessment: NEEDS_CHANGES | APPROVED | APPROVED_WITH_NOTES

### Critical Issues
1. [CATEGORY] — description
   **Finding type:** compliance | quality
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
- assessment: NEEDS_CHANGES if any Critical or open compliance findings, APPROVED_WITH_NOTES if only Important/Minor quality findings, APPROVED if no issues

## Interaction Rules

- Keep internal instructions in English
- If scope or artifact selection is ambiguous, ask before proceeding

## Workflow Log

{{@include:_shared/workflow-log.md}}

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Handoff

### Within a workflow task

After the report is saved, the next step depends on the assessment:

- **NEEDS_CHANGES** — the next fix command is `/cp-plan-fix`. {{INVOKE_SKILL}}
- **APPROVED / APPROVED_WITH_NOTES** — the plan is execution-ready. Present the result to the user and offer options:
  - **Execute in current session** — invoke `/cp-execute` ({{INVOKE_SKILL}}). Best when context is fresh and task is small.
  - **Hand off to a new session** — provide `/cp-execute <task-artifact-path>` for the user to run later. Best when context is heavy or upcoming work is long.

  Lead with your recommendation and explain why. **Wait for the user's explicit choice before proceeding.** Do not auto-invoke `/cp-execute` — the user must review the plan and confirm readiness.

### Ad hoc review (no active workflow task)

The save gate above already blocks file I/O. After the user makes their choice:
- If **save** — write the file, then offer `/cp-plan-fix`.
- If **run /cp-plan-fix now** — invoke `/cp-plan-fix` directly, passing findings through conversation context.

## Anti-patterns

Do NOT:
- **Review code instead of the plan** — this is a plan review, not code review
- **Issue findings without a concrete Fix** — an issue without a Fix is useless
- **Save ad hoc reports without user permission** — the ad hoc save gate is a hard requirement
- **Skip batch cross-consistency check** — if the plan uses batches, verify dependency graph and scope gaps
- **Treat minor style preferences as Critical findings** — severity must match actual risk

## Completion Criteria

This stage is complete when the plan review report exists and all findings are recorded with actionable resolutions.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
