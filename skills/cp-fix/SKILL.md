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
1. Check `.ai/tasks/` and `.ai/reports/` for report files with `open` findings. If multiple exist, list them and ask the user which one to work with. Use `AskUserQuestion` if available.
2. If the current conversation contains review results that were not saved to file, use those.
3. If no reports and no conversation context exist, inform the user: "No review report found. Run `/cp-review` first or provide a report path."

Do not guess which report to use when multiple candidates exist.

## Processing Order

Only process `open` findings. Process them **strictly in report order** — do not reorder by type, severity, or your own judgment. The review already places findings in the correct processing order.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create TodoWrite items **only for `open` findings**, in report order. Skip findings that are already `resolved` or `skipped`.

**Naming format:** each item MUST start with the finding number and severity from the report:
```
#1 [Critical] file:line — short description
#2 [Important] file:line — short description
#3 [Minor] file:line — short description
```

Mark each as `in_progress` when working on it and `completed` when bounded revalidation confirms the fix.

Create and update TodoWrite items in the same tool batch as the first read, fix dispatch, report edit, or verification when the platform supports batching. Otherwise update them with the nearest real action; never spend a separate turn only on tracking.

### Parallelization approval

After creating the full task list, if some findings are independent and can be fixed in parallel:
1. Present the proposed parallel groups to the user.
2. Wait for explicit approval before parallelizing.
3. If not approved, process all findings sequentially in report order.

Sequential processing is the default. Parallel processing requires user confirmation.

## Context Gathering

Before dispatching fix agents, read project rules from ``.claude/rules/*.md` and `CLAUDE.md``. Extract only the rule excerpts that apply to the current finding and pass them as cited `{APPLICABLE_RULES}` so the fixer receives the relevant constraints without the full project-rules payload.

## Subagent Model Policy

Choose the cheapest model that can handle the task. If the platform supports model selection for subagents, use it.

### Model Tiers

| Tier | Description | Use when |
|------|-------------|----------|
| **fast** | Cheapest/fastest available | Simple, well-scoped tasks with clear instructions |
| **default** | Mid-range | Most subagent work requiring comprehension and judgment |
| **powerful** | Most capable available | Complex reasoning, ambiguous constraints, tasks that failed at a lower tier |

### Platform Model Selection

Tiers are logical task categories, not platform model-role names. In particular, `default` does not
refer to a platform's `default` role or imply a fixed capability level. When a platform dispatches a
named agent definition, that definition selects the model or role.

### Ceiling Rule

Respect a capability ceiling only when the platform enforces one. Do not infer a ceiling from model-role
names or override the model selected by a platform agent definition.

### User Override

If project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers (e.g., `fast: haiku`,
`default: sonnet`), use it. User-defined mapping takes priority over automatic selection.

### Escalation on Failure

For failure handling and escalation, see Subagent Limits (included separately in each skill).

### Subagent Limits

Every dispatched subagent is bounded:

- **Max tool calls:** 30 per subagent. The subagent must return its best result within this budget.
- **Partial results:** if a subagent hits the limit before completing, it must return what it has gathered so far — not an empty or error response.

**Failure escalation chain:**

1. Subagent returns incomplete or unusable result → escalate model tier (per Model Tiers policy, max one escalation)
2. Escalated subagent still fails → treat as a blocker
3. Blocker handling: present partial results to the user, explain what the subagent could not complete, and offer options (continue manually, narrow scope, skip this pass)

Do not retry a subagent at the same tier. Do not wait indefinitely for a subagent response.

## Fixer Selection

Classify every finding before dispatching a fixer. Severity alone does not determine the execution tier:
- **simple** — an isolated, unambiguous repair with no public-contract change;
- **standard** — a local behavior change that requires code comprehension and focused verification;
- **complex** — security, concurrency, public API, migration, multi-module, or unclear-root-cause work.

Use the lowest tier that can safely handle the finding. On a failed or insufficient result, escalate once:
simple → standard → complex. Do not retry the same tier.

- After the user selects an option in the Fix Decision Brief, launch one Agent with the matching configured model tier: simple → fast, standard → default, complex → powerful. Pass exactly one finding, its selected option, and cited applicable rules; keep findings sequential unless the user approved an independent parallel group.

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

## Resolution Communication

Before explaining a fix, determine the language required by project rules. Write the explanation,
verification result, blocker, and report-resolution fields in that language. If rules do not specify a
language, use the language of the user's current conversation; a bare fix command inherits the preceding
user messages. If conversation language is unavailable, use the active user-facing language. Keep
identifiers, API names, paths, and code unchanged.

For every non-trivial fix, make the outcome understandable without reading the diff first:
- what changed;
- why that change closes the finding;
- which behavior or failure scenarios were verified;
- real trade-offs and risks introduced by the chosen fix, such as API or UX changes, compatibility,
  performance, operational complexity, or stricter validation.

When several reasonable fixes exist before editing, present each as `A)` / `B)` with what changes,
advantages, disadvantages, and when to choose it. Do not invent alternatives or trade-offs for a simple,
unambiguous repair, such as adding a clearly missing test.

Order of operations per finding:
1. Apply fix (or decide to skip)
2. Run bounded revalidation
3. **Persist tracking update (mandatory):**
   - If a report file exists → **edit the report file right now** using the Edit tool
   - If no file (context-only mode) → record the update in conversation memory
4. Mark the TodoWrite item as completed
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
When asking the user, use `AskUserQuestion` if available on the current platform.

## Anti-patterns

Do NOT:
- **Batch report updates to the end** — update tracking fields immediately after each finding, not in bulk
- **Reorder findings by type, severity, or your own judgment** — always preserve report order as-is
- **Skip bounded revalidation** — every fix must be verified before being marked resolved
- **Save ad hoc reports without user permission** — offer to save, do not auto-save
- **Parallelize without user approval** — sequential processing is the default
- **Skip documentation check** — always check if `.ai/docs/` needs updating after fixes

## Completion Criteria

This skill is complete when selected findings are resolved with evidence and final verification passes. If a blocker is hit mid-process, the skill stops with a summary of what was resolved, what remains, and what caused the stop.
