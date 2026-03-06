---
name: cpfix
description: Fix issues found during code review
---

# /cpfix

Process open findings from `/cpreview`.

## Source

Accept either:
- a saved review report path (explicit argument)
- the latest review report from the current workflow task
- the current conversation context if review just finished

### No-argument behavior

When invoked without arguments:
1. Check for an active workflow task — if it has a single report with `open` findings, use it.
2. If multiple reports with `open` findings exist (across `.ai/tasks/` and `.ai/reports/`), list them and ask the user which one to work with. Use `{{ASK_USER}}` if available.
3. If the current conversation contains review results that were not saved to file, use those.

Do not guess which report to use when multiple candidates exist.

## Processing Order

Only process `open` findings.

Default priority:
1. `compliance`
2. `quality`

Do not move to quality findings while unresolved compliance findings remain, unless one combined change is clearly safer and still keeps the review trail understandable.

Within each group, preserve the original order from the report. Do not reorder findings by your own judgment.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create {{PROGRESS_TOOL}} items **only for `open` findings**, in report order. Skip findings that are already `resolved`, `skipped`, or `deferred`.

**Naming format:** each item MUST start with the finding number and severity from the report:
```
#1 [Critical] file:line — short description
#2 [Important] file:line — short description
#3 [Minor] file:line — short description
```

Mark each as `in_progress` when working on it and `completed` when bounded revalidation confirms the fix.

### Parallelization approval

After creating the full task list, if some findings are independent and can be fixed in parallel:
1. Present the proposed parallel groups to the user.
2. Wait for explicit approval before parallelizing.
3. If not approved, process all findings sequentially in report order.

Sequential processing is the default. Parallel processing requires user confirmation.

## Fix Policy

Before starting fixes, determine:

**Severity scope:**
- critical only
- critical + important
- all

**Processing style:**
- manual per item
- auto simple, ask-user for complex cases
- custom user-defined policy

If policy is not already clear, ask the user.

## Execution Rules

- process findings in report order (see Parallelization approval for exceptions)
- update report tracking fields after each fix
- allow alternative fixes when there are real trade-offs
- run bounded revalidation before closing each finding

### Final Verification Pass

After all fixes, run all relevant project checks:
- lint
- tests
- build or typecheck if applicable
- other mandatory checks from project rules

Bounded revalidation after fixes must first confirm that compliance risks are actually closed, and only then consider the quality fix cycle complete.

If fixes lead to conflicting findings, unclear fix policy, or repeated revalidation failure, treat it as a blocker and stop.

## Report Mutation (incremental, mandatory)

Update the report file **immediately after each finding** is resolved, skipped, or deferred — not in a batch at the end. This is a hard requirement for resumability: the session may be interrupted at any point, and the next `/cpfix` run must see which findings are already handled.

For each processed finding, update in the report file:
- **Status:** `open` → `resolved` | `skipped` | `deferred`
- **Resolved via:** what was changed (file:line, commit, or "skipped")
- **Resolution notes:** brief explanation

Order of operations per finding:
1. Apply fix (or decide to skip/defer)
2. Run bounded revalidation
3. **Persist tracking update (mandatory — do this, not skip):**
   - If a report file exists → **edit the report file right now** using the Edit tool. Find this finding's block and replace:
     - `**Status:** open` → `**Status:** resolved` (or `skipped` / `deferred`)
     - `**Resolved via:**` → `**Resolved via:** <what was changed, e.g. file:line or "skipped">`
     - `**Resolution notes:**` → `**Resolution notes:** <brief explanation>`
   - If no file (context-only mode) → record the update in conversation memory
4. Mark the {{PROGRESS_TOOL}} item as completed
5. Move to the next finding

**Not updating the report file after each finding is a workflow violation.** The file is the source of truth for resumability.

### Mid-process save

If the user asks to save the report at any point during the fix process, immediately:
1. Write the report file to `.ai/reports/` with all current tracking state (already resolved + still open findings). Use `mkdir -p` for the directory — do not check existence separately or ask permission.
2. From this point forward, the file exists — all subsequent findings use file-based persistence in step 3 above.

### End of process (context-only mode)

If no report file was created during the process, the ad hoc save gate at the end offers to write the final report.

The report remains the resumable source of truth across `/cpfix` runs.

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

## Completion Criteria

This stage is complete when selected findings are resolved with evidence, compliance findings are handled first, and final verification is fresh.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.

## Code Path Complete

### Within a workflow task

After `/cpfix` and final verification, the code path is complete but the workflow task is not.

Next mandatory step: `/cpdocs` — either in the current session or a new one. {{INVOKE_SKILL}}
Do not automatically clean up branches, worktrees, or execution environment.
Cleanup is allowed only as an explicit decision considering the next workflow step.

### Ad hoc fix (no active workflow task)

After all fixes and final verification, the work is complete. No `/cpdocs` handoff is required.

If the source report was a saved file, update its tracking fields as usual.

#### STOP — Ad Hoc Save Gate (mandatory)

If findings were passed through conversation context (no saved file), you MUST NOT write any report file until the user explicitly chooses to save. This is a hard gate — no exceptions.

Flow:
1. Present the completed report with all resolution tracking fields **in conversation only**.
2. Ask the user (use `{{ASK_USER}}` if available):
   - **Save report to file** — only then write to `.ai/reports/`
   - **Do not save** — findings and resolutions stay in conversation only
3. Wait for the user's explicit choice before any file I/O.

Violating this gate (saving before asking) is a critical workflow error.
