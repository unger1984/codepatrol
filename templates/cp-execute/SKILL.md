---
name: cp-execute
description: Use to implement features, changes, or fixes from a plan with verification checkpoints
---

# /cp-execute

Run implementation from the approved `plan.md`.

## No-argument behavior

When invoked without arguments:
1. Check for an active workflow task in `.ai/tasks/` with an approved plan ready for execution.
2. If exactly one candidate exists, use it.
3. If multiple candidates exist, list them and ask the user. Use `{{ASK_USER}}` if available.
4. If no candidates exist, inform the user: "No task with execution-ready plan found. Run `/cp-idea` first or provide a task path."

## Progress Tracking (mandatory)

Before starting execution, you MUST create {{PROGRESS_TOOL}} items for each plan stage.
Mark each as `in_progress` when a stage begins and `completed` when verification passes.
This provides visual progress to the user.

Example:
- [ ] Preflight checks
- [ ] Stage 1: <objective>
- [ ] Stage 2: <objective>
- [ ] Final verification
- [ ] Handoff to /cp-review

## Preconditions

Execution requires:
- a current workflow task
- an approved design state when design was needed
- a current plan file
- completed `/cp-plan-review`
- one of:
  - `/cp-plan-review` assessment is APPROVED or APPROVED_WITH_NOTES — this is sufficient, `/cp-plan-fix` is not required
  - `/cp-plan-review` assessment is NEEDS_CHANGES — completed `/cp-plan-fix` with bounded revalidation showing the plan is execution-ready

Do not execute directly from a chat summary when a plan artifact should exist.

## Execution Preflight

Before editing code:
- load the current `plan.md` (master file)
- if the plan uses batch files, load only the next pending batch — not all batches at once
- load relevant workflow decisions from `workflow.md`
- read project rules from `{{RULES_SOURCE}}` — these are passed to implementer subagents
- if `.ai/docs/README.md` exists, read it and only the relevant docs
- confirm the target branch is safe for implementation
- identify required verification commands for the current batch or plan segment
- {{FILE_DISCOVERY}}

If branch safety is unclear, stop and ask. Do not start implementation on `main` or `master` without explicit user approval.

## Execution Strategy

Before starting implementation:
- read the plan as an execution contract
- build an execution graph from stages and key steps
- derive dependencies and safe parallelization zones
- choose execution strategy based on plan header and actual project state
- if multiple meaningful execution strategies exist, ask the user

**Batched plans:** execute one batch at a time. After each batch:
- run batch verification
- update batch status in the master `plan.md` (`pending` → `done`)
- apply checkpoint discipline (see below)
- load the next pending batch

Independent batches may be parallelized via subagents if the dependency graph allows it.

Prefer minimal sufficient context for each implementation unit.
Do not silently change the design or plan intent during execution.

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

Assess each plan step's complexity and assign the starting tier accordingly.

## Implementer Subagent Contract

Each implementing subagent must:
- follow project rules, style, and architectural constraints
- work only within its assigned scope
- run a local self-check before handoff
- verify nearest impact from its changes
- run relevant lint, tests, and checks available in the project
- fix obvious problems within its own scope
- escalate conflicts between the plan, code, and rules back to the executor

## Execution Rules

- follow the plan in order unless the plan itself justifies safe parallelization
- keep checkpoint reporting concise and tied to completed plan items
- stop on blockers instead of guessing
- record meaningful execution decisions back into workflow state when applicable
- require fresh verification evidence before marking work complete

## Checkpoint Reporting

Each checkpoint should state:
- what plan items were executed
- what verification ran
- what remains open
- blockers, new risks, or open trade-offs if any

The user-facing wording should use display names like `execution` and `code review`, not internal stage ids.

### Checkpoint Discipline

After each stage or group of parallel stages, run all relevant project checks:
- linters, formatters, static analysis
- tests
- build or typecheck if applicable
- other mandatory checks from project rules

If checks fail, attempt to fix and rerun (max 3 attempts per checkpoint). After 3 failures, treat as a blocker and ask the user.

### Continue / Pause / Handoff Decision

Automatic continuation is allowed only when:
- the current checkpoint is confirmed by relevant checks
- no new significant trade-offs appeared
- the next step is low-risk

Pause is mandatory when:
- a major stage or parallel group is completed
- the risk profile changed
- the next step substantially changes the type of work
- a handoff to a new session is worth recommending

### Session Mode Heuristic

Prefer current session when:
- context is still fresh and compact
- the task is small enough
- trade-offs are already closed

Prefer new session when:
- task artifacts are self-contained
- upcoming work is long or multi-stage
- current context is already heavy

Provide a reasoned recommendation, but leave the final choice to the user.

## Handoff To /cp-review

When implementation is complete, offer two paths:
- **continue now** — invoke `/cp-review` ({{INVOKE_SKILL}})
- **hand off to a new session** — provide `/cp-review <task-artifact-path>` for the user to run later

When the user chooses to continue, invoke `/cp-review` immediately. Do not tell the user to run it manually. Manual invocation is only for handing off to a new session.

The review side must be able to restore context from task artifacts and reports.

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

## Anti-patterns

Do NOT:
- **Silently change the design or plan intent during execution** — if a deviation is needed, escalate to the user
- **Skip checkpoint verification** — every stage must have fresh passing evidence before proceeding
- **Guess past blockers** — stop and ask instead of working around ambiguity
- **Execute directly from chat without a plan artifact** — always load the plan file
- **Load all batch files at once** — load only the current pending batch to keep context compact
- **Start implementation on main/master without explicit user approval**

## Completion Criteria

Execution is complete only when:
- implementation required by the current plan is done
- relevant checks have fresh passing evidence
- workflow state reflects the result
- the task is ready for `/cp-review`

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
