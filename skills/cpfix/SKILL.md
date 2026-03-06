---
name: cpfix
description: Fix open code review findings from cpreview with priority for compliance before quality
---

# /cpfix

Process open findings from `/cpreview`.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create TodoWrite items for each open finding.
Mark each as `in_progress` when working on it and `completed` when bounded revalidation confirms the fix.
This provides visual progress to the user.

## Source

Accept either:
- a saved review report path
- the latest review report from the current workflow task
- the current conversation context if review just finished

If the source is ambiguous, ask before proceeding.

## Processing Order

Only process `open` findings.

Default priority:
1. `compliance`
2. `quality`

Do not move to quality findings while unresolved compliance findings remain, unless one combined change is clearly safer and still keeps the review trail understandable.

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

- parallelize only independent fixes
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
3. **Persist tracking update:**
   - If a report file exists → write updated fields to the file immediately
   - If no file (context-only mode) → record the update in conversation memory
4. Mark the TodoWrite item as completed
5. Move to the next finding

### Mid-process save

If the user asks to save the report at any point during the fix process, immediately:
1. Write the report file to `.ai/reports/` with all current tracking state (already resolved + still open findings).
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

When asking the user, use `AskUserQuestion` if available on the current platform.

## Completion Criteria

This stage is complete when selected findings are resolved with evidence, compliance findings are handled first, and final verification is fresh.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.

## Code Path Complete

### Within a workflow task

After `/cpfix` and final verification, the code path is complete but the workflow task is not.

Next mandatory step: `/cpdocs` — either in the current session or a new one. Use the Skill tool to invoke the target skill directly.
Do not automatically clean up branches, worktrees, or execution environment.
Cleanup is allowed only as an explicit decision considering the next workflow step.

### Ad hoc fix (no active workflow task)

After all fixes and final verification, the work is complete. No `/cpdocs` handoff is required.

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
