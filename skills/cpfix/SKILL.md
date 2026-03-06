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

## Report Mutation

For each processed finding, update:
- status
- resolved via
- resolution notes

The report remains resumable across future `/cpfix` runs.

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

After `/cpfix` and final verification, the code path is complete but the workflow task is not.

Next mandatory step: `/cpdocs` — either in the current session or a new one. Use the Skill tool to invoke the target skill directly.
Do not automatically clean up branches, worktrees, or execution environment.
Cleanup is allowed only as an explicit decision considering the next workflow step.
