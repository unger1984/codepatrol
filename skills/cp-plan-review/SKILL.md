---
name: cp-plan-review
description: Review an implementation plan for correctness, compliance, and readiness
---

# /cp-plan-review

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

- the current `plan.md` (master file with batch index if batched)
- all `plan-batch-NN.md` files when present
- the current `workflow.md`
- the approved `design.md` when present
- relevant project rules from ``.claude/rules/*.md` and `CLAUDE.md``
- targeted project docs starting from `.ai/docs/README.md` if it exists

**Batched plans:** when a plan uses batch files, review each batch independently but also verify cross-batch consistency (dependency graph, shared contracts, no scope gaps between batches).

## Execution Model

- **simple plans** (few checklist items, narrow scope) — the orchestrator runs all checks directly
- **medium and large plans** — the orchestrator may dispatch checklist groups to subagents:
  - design consistency and scope → default tier
  - execution readiness and verification → default tier
  - docs/operational impact → fast tier
- Launch reviewers in parallel using Agent tool with `run_in_background=true`. Send all Agent calls in a single message for true parallelism. Use the `model` parameter to set the model tier for each subagent.
- all findings from subagents must be normalized into one report

## Subagent Model Policy

Choose the cheapest model that can handle the task. If the platform supports model selection for subagents, use it.

### Model Tiers

| Tier | Description | Use when |
|------|-------------|----------|
| **fast** | Cheapest/fastest available | Simple, well-scoped tasks with clear instructions |
| **default** | Mid-range | Most subagent work requiring comprehension and judgment |
| **powerful** | Most capable available | Complex reasoning, ambiguous constraints, tasks that failed at a lower tier |

### Ceiling Rule

The current session model is the ceiling. Subagents cannot use a more capable model than the orchestrator.

### User Override

If project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers (e.g., `fast: haiku`, `default: sonnet`), use it. User-defined mapping takes priority over automatic selection.

### Escalation on Failure

If a subagent returns an error, produces empty or unusable output, or fails its task:
1. **Do not retry at the same tier.** Escalate to the next tier up (fast → default → powerful), respecting the ceiling.
2. Re-dispatch the same task with the higher-tier model.
3. Maximum one escalation per subagent. If the ceiling tier fails, treat it as a blocker and ask the user.
4. Log the escalation in the progress update so the user sees it.

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
3. Ask the user (use `AskUserQuestion` if available) which action to take:
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

### Workflow Log

Workflow logging is **disabled by default**. It is enabled when the file `.ai/.enable-log` exists in the project root. If the file does not exist, skip all logging — do not create the `## Log` section in `workflow.md` and do not append entries.

To check: before the first log write, verify that `.ai/.enable-log` exists. If it does not, skip logging for the entire workflow run. Do not re-check on every event.

#### Log language

Write log entries in the language specified by project rules (CLAUDE.md, AGENTS.md). If the user explicitly specifies a log language when creating the task, use their choice instead. Fallback: English.

#### When to log

Append entries to the `## Log` section of `workflow.md` at these points:
- **skill invoked** — which skill started, how (auto-invoked, user-invoked, resumed), and purpose
- **subagent dispatched** — role, brief result (count of findings, conflicts, gaps)
- **user interaction** — brief summary of question asked and user's answer or decision (not the full dialogue)
- **decision made** — what was decided and why (approach chosen, scope narrowed, parameter set)
- **context check** — what was verified when transitioning between skills (design status, rules, file map)
- **skill completed** — brief outcome (e.g. "plan ready, 0 rule violations" or "3 critical, 2 important findings")
- **blocker hit** — what blocked and how it was resolved
- **deviation** — unexpected events: model escalation, retry, approach change, scope change mid-workflow

#### Log format

Each entry starts with a timestamp and skill name. Entries may be 1-5 lines. Use nested bullets for structured details.

```
- `HH:MM` **/skill** — action summary
  - detail 1
  - detail 2
```

Use `date +%H%M` for the timestamp. Do not guess the time.

#### Examples

```
- `10:49` **/cp-idea** clarification complete
  - scope: standard, severity: Minor, new dimension: Compatibility
  - user confirmed rules override via prompt instruction
- `10:52` **/cp-idea** research subagent dispatched → 3 findings, no conflicts
  - review structure: 3 severity levels, 4 dimensions
- `10:55` **/cp-idea** user chose approach: new Compatibility dimension with dedicated reviewer
- `10:58` **/cp-idea** research refresh → no conflicts, format confirmed
- `13:52` **/cp-idea** design approved, auto-invoking /cp-plan
- `13:54` **/cp-plan** context check passed
  - design: approved, execution strategy: /cp-execute (small task)
  - file map: 1 new, 1 modified, 2 docs
- `13:55` **/cp-plan** plan written (4 stages), rules pre-check passed
  - auto-invoking /cp-plan-review
- `13:56` **/cp-plan-review** APPROVED, 0 findings
  - user confirmed plan, proceeding to execution
- `14:06` **/cp-execute** all 4 stages done, build passes
- `14:07` **/cp-review** APPROVED, 0 findings — workflow complete
- `14:10` **/cp-idea** deviation: research subagent failed at fast tier, escalated to default → success
```

#### Rules

- Do not log internal reasoning, full agent prompts, or file contents
- Do not log the full text of user messages — summarize the intent and decision
- Do not include code snippets in log entries
- Keep each entry concise — enough to reconstruct the workflow flow, not to replay it
- The log must be sufficient for post-hoc analysis: what happened, what was decided, and why

Skip logging when there is no active workflow task (ad hoc mode).

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

After the report is saved, the next step depends on the assessment:

- **NEEDS_CHANGES** — the next fix command is `/cp-plan-fix`. Use the Skill tool to invoke the target skill directly.
- **APPROVED / APPROVED_WITH_NOTES** — the plan is execution-ready. Present the result to the user and offer options:
  - **Execute in current session** — invoke `/cp-execute` (Use the Skill tool to invoke the target skill directly.). Best when context is fresh and task is small.
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
