---
name: cpplanfix
description: Fix open plan review findings, mutate tracking fields, and run bounded revalidation
---

# /cpplanfix

Process open findings from `/cpplanreview`.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create TodoWrite items for each open finding.
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

If `AskUserQuestion` is available, use it. Otherwise ask in chat.

## Bounded Revalidation

Revalidation must confirm that:
- the addressed finding is actually closed
- the updated plan remains consistent with design and workflow rules
- unrelated plan sections were not silently regressed

Do not rerun the entire workflow unless the change requires it. Keep revalidation bounded to the impacted surface.

## Report Mutation (incremental, mandatory)

Update the report file **immediately after each finding** is resolved, skipped, or deferred — not in a batch at the end. This is a hard requirement for resumability: the session may be interrupted at any point, and the next `/cpplanfix` run must see which findings are already handled.

For each processed finding, update in the report file:
- **Status:** `open` → `resolved` | `skipped` | `deferred`
- **Resolved via:** what was changed
- **Resolution notes:** brief explanation

Order of operations per finding:
1. Apply fix to the plan (or decide to skip/defer)
2. Run bounded revalidation
3. **Persist tracking update (mandatory — do this, not skip):**
   - If a report file exists → **edit the report file right now** using the Edit tool. Find this finding's block and replace:
     - `**Status:** open` → `**Status:** resolved` (or `skipped` / `deferred`)
     - `**Resolved via:**` → `**Resolved via:** <what was changed>`
     - `**Resolution notes:**` → `**Resolution notes:** <brief explanation>`
   - If no file (context-only mode) → record the update in conversation memory
4. Mark the TodoWrite item as completed
5. Move to the next finding

**Not updating the report file after each finding is a workflow violation.** The file is the source of truth for resumability.

### Mid-process save

If the user asks to save the report at any point during the fix process, immediately:
1. Write the report file to `.ai/reports/` with all current tracking state (already resolved + still open findings). Use `mkdir -p` for the directory — do not check existence separately or ask permission.
2. From this point forward, the file exists — all subsequent findings use file-based persistence in step 3 above.

### End of process (context-only mode)

If no report file was created during the process, the ad hoc save gate at the end offers to write the final report.

The report remains the resumable source of truth across `/cpplanfix` runs.

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

#### STOP — Ad Hoc Save Gate (mandatory)

If findings were passed through conversation context (no saved file), you MUST NOT write any report file until the user explicitly chooses to save. This is a hard gate — no exceptions.

Flow:
1. Present the completed report with all resolution tracking fields **in conversation only**.
2. Ask the user (use `AskUserQuestion` if available):
   - **Save report to file** — only then write to `.ai/reports/`
   - **Do not save** — findings and resolutions stay in conversation only
3. Wait for the user's explicit choice before any file I/O.

Violating this gate (saving before asking) is a critical workflow error.
