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

## Fix Intake Gate

`/cp-fix`, “fix it”, “do it”, or an equivalent request authorizes intake only. It does not select a fix policy.

Before any code edit, fixer dispatch, fix command, report-status mutation, or progress update, state the count of
open findings and ask the user to choose:

1. **Severity scope:** critical only / critical + important / all.
2. **Processing style:** manual per item / auto safe fixes with approval for consequential or ambiguous work / custom policy.

Treat a policy as selected only when the current conversation contains an explicit option choice or an applicable
project rule states one. A generic request to start fixing is not a selected policy.

Use `{{ASK_USER}}` when available. Otherwise ask the same numbered question in a normal user-facing message and
wait for an explicit reply. Tool unavailability never authorizes a policy assumption or workflow continuation.

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

Create and update {{PROGRESS_TOOL}} items in the same tool batch as the first read, fix dispatch, report edit, or verification when the platform supports batching. Otherwise update them with the nearest real action; never spend a separate turn only on tracking.

### Parallelization approval

After creating the full task list, if some findings are independent and can be fixed in parallel:
1. Present the proposed parallel groups to the user.
2. Wait for explicit approval before parallelizing.
3. If not approved, process all findings sequentially in report order.

Sequential processing is the default. Parallel processing requires user confirmation.
When `{{ASK_USER}}` is unavailable, present the proposed groups as a numbered normal user-facing question and wait
for an explicit reply.

## Context Gathering

Discover project-rule files with `Glob` before reading. Read only paths returned by `Glob`; if none match,
there are no project-rule excerpts to pass to the fixer. Never pass `{{RULES_SOURCE}}` or any glob to `Read`.

Before dispatching fix agents, read project rules from `{{RULES_SOURCE}}`. Extract only the rule excerpts that apply to the current finding and pass them as cited `{APPLICABLE_RULES}` so the fixer receives the relevant constraints without the full project-rules payload.

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

{{@include:_shared/subagent-limits.md}}

## Fixer Selection

Classify every finding before dispatching a fixer. Severity alone does not determine the execution tier:
- **simple** — an isolated, unambiguous repair with no public-contract change;
- **standard** — a local behavior change that requires code comprehension and focused verification;
- **complex** — security, concurrency, public API, migration, multi-module, or unclear-root-cause work.

Use the lowest tier that can safely handle the finding. On a failed or insufficient result, escalate once:
simple → standard → complex. Do not retry the same tier.

{{@platform-include:fixer-dispatch}}

## Fix Policy

Before starting fixes, determine:

**Severity scope** (applies to quality findings only — compliance findings are always processed regardless of this setting):
- critical only
- critical + important
- all

**Processing style:**
- manual per item
- auto safe fixes, ask before consequential or ambiguous fixes
- custom user-defined policy

If policy is not already clear, ask the user.

## Fix Decision Brief

Before any fix decision, prepare a plain-language brief for the current finding that includes:
- the problem and what triggered it
- the recommended fix
- any materially different alternative fixes
- for each option: what changes, benefits, drawbacks or risks, affected files, and verification

Use a concise brief only when the finding qualifies for an automatic safe fix. Use the full brief and require an explicit user choice for any standard or complex finding, any ambiguous fix, any unclear root cause or unclear verification, and any finding involving security, auth, payments, PII, migrations, public APIs, dependency upgrades, data deletion, performance, or availability.

## Manual Per Item Gate

When the processing style is `manual per item`, stop on each finding after preparing the Fix Decision Brief. Do not dispatch a fixer, edit files, run a fix command, or mutate finding status or resolution fields until the user explicitly chooses one option, skips the finding, or stops the workflow for that finding.

## Execution Rules

- dispatch exactly one finding per fixer
- update report tracking fields after each fix
- run bounded revalidation before closing each finding
- preserve alternative fixes when there are real trade-offs: auto-apply only the single safe option, ask the user when multiple valid fixes or materially different consequences exist

An automatic safe fix is allowed only when there is one isolated simple repair, one safe option, no observable behavior, public API, schema, or config change, and rollback is trivial.

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
- **Resolution notes:** for a non-trivial fix, what changed, why it closes the finding, verification, and material trade-offs or risks

{{@include:_shared/resolution-writing.md}}

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
- verification or revalidation fails after 3 attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Batch report updates to the end** — update tracking fields immediately after each finding, not in bulk
- **Reorder findings by type, severity, or your own judgment** — always preserve report order as-is
- **Skip bounded revalidation** — every fix must be verified before being marked resolved
- **Save ad hoc reports without user permission** — offer to save, do not auto-save
- **Parallelize without user approval** — sequential processing is the default
- **Bypass the Fix Intake Gate** — never treat a generic request to start as a selected policy or mutate anything before explicit choices
- **Skip documentation check** — always check if `.ai/docs/` needs updating after fixes

## Completion Criteria

This skill is complete when selected findings are resolved with evidence and final verification passes. If a blocker is hit mid-process, the skill stops with a summary of what was resolved, what remains, and what caused the stop.
