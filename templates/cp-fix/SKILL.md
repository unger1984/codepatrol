---
name: cp-fix
description: Fix issues found during code review
---

# /cp-fix

Process open findings from `/cp-review`.

## Source

Accept either:
- a saved review report path (explicit argument)
- the current conversation context if review just finished

### No-argument behavior

When invoked without arguments:
1. Check `.ai/tasks/` and `.ai/reports/` for report files with `open` findings. If multiple exist, list them and ask the user which one to work with. Use `{{ASK_USER}}` if available.
2. If the current conversation contains review results that were not saved to file, use those.
3. If no reports and no conversation context exist, inform the user: "No review report found. Run `/cp-review` first or provide a report path."

Do not guess which report to use when multiple candidates exist.

## Processing Order

Only process `open` findings. Process them **strictly in report order** — do not reorder by type, severity, or your own judgment. The review already places findings in the correct processing order.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create {{PROGRESS_TOOL}} items **only for `open` findings**, in report order. Skip findings that are already `resolved` or `skipped`.

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

## Context Gathering

Before dispatching fix agents, read project rules from `{{RULES_SOURCE}}`. Pass the rules summary as `{PROJECT_RULES}` to each fix agent so it can respect codestyle, testing, and naming conventions.

## Fix Policy

Before starting fixes, determine:

**Severity scope** (applies to quality findings only — compliance findings are always processed regardless of this setting):
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
- allow alternative fixes when there are real trade-offs: auto-fix when intent is clear, ask the user when multiple valid fixes exist
- run bounded revalidation before closing each finding

### Final Verification Pass

After all fixes, run all relevant project checks:
- lint
- tests
- build or typecheck if applicable
- other mandatory checks from project rules

Bounded revalidation after fixes must confirm that the addressed risks are actually closed before marking each finding resolved.

If fixes lead to conflicting findings, unclear fix policy, or repeated revalidation failure, treat it as a blocker and stop.

## Report Mutation (incremental, mandatory)

**First line preservation:** the first line of a report file is reserved for processing metadata. Never modify, move, or remove it when editing the report.

Update the report file **immediately after each finding** is resolved or skipped — not in a batch at the end. This is a hard requirement for resumability.

For each processed finding, update in the report file:
- **Status:** `open` → `resolved` | `skipped`
- **Resolved via:** what was changed (file:line, commit, or "skipped")
- **Resolution notes:** brief explanation

Order of operations per finding:
1. Apply fix (or decide to skip)
2. Run bounded revalidation
3. **Persist tracking update (mandatory):**
   - If a report file exists → **edit the report file right now** using the Edit tool
   - If no file (context-only mode) → record the update in conversation memory
4. Mark the {{PROGRESS_TOOL}} item as completed
5. Move to the next finding

**Not updating the report file after each finding is a workflow violation.**

### End of process (context-only mode)

If no report file was created during the process, offer to write the final report with all resolution tracking.

## Documentation Check

After all fixes and final verification, check if the changes affect anything documented in `.ai/docs/`. If so, inform the user that documentation may need updating.

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Batch report updates to the end** — update tracking fields immediately after each finding, not in bulk
- **Reorder findings by type, severity, or your own judgment** — always preserve report order as-is
- **Skip bounded revalidation** — every fix must be verified before being marked resolved
- **Save ad hoc reports without user permission** — offer to save, do not auto-save
- **Parallelize without user approval** — sequential processing is the default
- **Skip documentation check** — always check if `.ai/docs/` needs updating after fixes

## Completion Criteria

This skill is complete when selected findings are resolved with evidence and final verification passes.
