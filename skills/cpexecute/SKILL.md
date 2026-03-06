---
name: cpexecute
description: Use to implement features, changes, or fixes from a plan with verification checkpoints
---

# /cpexecute

Run implementation from the approved `plan.md`.

## Progress Tracking (mandatory)

Before starting execution, you MUST create TodoWrite items for each plan stage.
Mark each as `in_progress` when a stage begins and `completed` when verification passes.
This provides visual progress to the user.

Example:
- [ ] Preflight checks
- [ ] Stage 1: <objective>
- [ ] Stage 2: <objective>
- [ ] Final verification
- [ ] Handoff to /cpreview

## Preconditions

Execution requires:
- a current workflow task
- an approved design state when design was needed
- a current plan file
- completed `/cpplanreview`
- completed `/cpplanfix`
- bounded revalidation showing the plan is execution-ready

Do not execute directly from a chat summary when a plan artifact should exist.

## Execution Preflight

Before editing code:
- load the current `plan.md`
- load relevant workflow decisions from `workflow.md`
- if `.ai/docs/README.md` exists, read it and only the relevant docs
- confirm the target branch is safe for implementation
- identify required verification commands for each plan segment
- For file discovery, use Glob, Grep, or MCP filesystem tools if available. Do not fall back to shell commands (find, grep) unless no dedicated tool is available.

If branch safety is unclear, stop and ask. Do not start implementation on `main` or `master` without explicit user approval.

## Execution Strategy

Before starting implementation:
- read the plan as an execution contract
- build an execution graph from stages and key steps
- derive dependencies and safe parallelization zones
- choose execution strategy based on plan header and actual project state
- if multiple meaningful execution strategies exist, ask the user

Prefer minimal sufficient context for each implementation unit.
Do not silently change the design or plan intent during execution.

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

If checks fail, attempt to fix and rerun. Ask the user only after reasonable attempts fail.

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

## Handoff To /cpreview

When implementation is complete, do not silently launch review.

Offer two paths:
- review now with `/cpreview` — Use the Skill tool to invoke the target skill directly.
- hand off to a new session with `/cpreview <task-artifact-path>`

The review side must be able to restore context from task artifacts and reports.

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

Execution is complete only when:
- implementation required by the current plan is done
- relevant checks have fresh passing evidence
- workflow state reflects the result
- the task is ready for `/cpreview`

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
