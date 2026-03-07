---
name: cp-plan
description: Write an implementation plan from an approved design with project rules awareness
---

# /cp-plan

Write an implementation plan from the approved design.

## No-argument behavior

When invoked without arguments:
1. Check for an active workflow task in `.ai/tasks/` with an approved design and no existing plan.
2. If exactly one candidate exists, use it.
3. If multiple candidates exist, list them and ask the user. Use `{{ASK_USER}}` if available.
4. If no candidates exist, inform the user: "No task with approved design found. Run `/cp-idea` first or provide a task path."

## Model Policy

This command performs plan decomposition — heavy reasoning work. Run on the orchestrator directly.

If a research refresh is needed (new session, missing context), dispatch a research subagent. See the context readiness gate below.

{{DISPATCH_AGENT}}

**Ceiling rule:** subagents cannot use a more capable model than the orchestrator session.

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

## Progress Tracking (mandatory)

Before starting work, you MUST create {{PROGRESS_TOOL}} items for each stage.
Mark each as `in_progress` when entering a stage and `completed` when stage criteria are met.

Required items:
- [ ] Context readiness check
- [ ] Commit strategy
- [ ] Write plan
- [ ] Rules compliance pre-check
- [ ] Handoff to /cp-plan-review

## Context Readiness Gate

Before writing the plan, verify that the following context is available. Do not proceed until all items are confirmed.

**Required context:**
- **Design** — approved `design.md` contents, including execution strategy section
- **Project rules** — codestyle, testing strategy, linting, commit conventions, CI pipeline, migration policy — everything that constrains how code is written and verified
- **File map** — which files will be created, modified, or deleted; their current state (exist? key contents?)
- **Contracts** — interfaces, signatures, data structures, dependencies between modules that the plan must respect

**How to obtain missing context:**

| Situation | Action |
|-----------|--------|
| Called from `/cp-idea` in the same session | Context is already available. Verify completeness, fill gaps with targeted file reads. |
| Called in a new session or context is insufficient | Dispatch a research subagent with extended scope (see below). |

**Research for planning context:**

{{DISPATCH_RESEARCHER}}

**Researcher prompt:**

{{@include:_shared/researcher.md}}

**Query construction:** formulate a query that covers all missing context items. Include:
- design.md and workflow.md paths (to read decisions and verify design freshness)
- request to verify design consistency with current code (files exist, interfaces unchanged)
- request to collect project rules from `{{RULES_SOURCE}}`
- request to build a file map: files to create/modify/delete with current state
- request to identify contracts: interfaces, signatures, data structures involved
- scope hints: paths from design's impact analysis

If the design is stale or has conflicts, stop and ask the user before proceeding.

<HARD-GATE>
Do NOT start writing the plan until all required context items are confirmed. A plan written without full context leads to review findings that could have been prevented. This gate exists because fixing a plan is more expensive than reading one more file.
</HARD-GATE>

## Commit Strategy

Before writing the plan, determine the commit strategy.

If project rules or CLAUDE.md/AGENTS.md define a commit strategy, use it.
Otherwise, ask the user. Use `{{ASK_USER}}` if available.

Supported strategies:
- no intermediate commits
- commit per stage
- commit per step
- custom strategy for the specific task

The chosen strategy affects plan structure, checkpoints, execution safety, parallelization, and rollback safety.

## Plan File Format

One plan file per workflow task: `<task-slug>.plan.md` inside the task folder.
The file is edited iteratively after review/fix.

Role: act as senior technical lead / delivery architect.

**Plan header must include:**
- link to design file
- link to plan file
- task slug
- creation time
- goal
- scope
- execution mode
- execution model (default: current model; if a weaker model is specified, adapt granularity)
- recommended skills and agents
- high-level parallelization strategy
- commit strategy
- constraints
- verification and documentation strategy

**Plan body must include:**
- stages with objectives
- key steps per stage
- verification per stage
- commit expectations per stage

### Plan Granularity by Executor Tier

Plan detail adapts to who will execute it. The executor tier is set in the design's execution strategy section.

| Executor tier | Granularity | What the plan contains |
|---------------|-------------|----------------------|
| Strong (Opus) | Strategic | Stages, objectives, verification criteria, contracts (interfaces, signatures, key algorithms in pseudocode) |
| Mid (Sonnet) | Tactical | Key steps with pseudocode, data structures, interaction patterns — not full code |
| Weak (Haiku) | Detailed | Near-complete code, exact commands, micro-steps |
| Human | Strategic + pointers | Stages, objectives, verification criteria, links to relevant code and docs |

Even at the strategic level, the plan must contain **contracts** — interfaces, signatures, data structures, key algorithms in pseudocode. This ensures architectural decisions are persisted and survive session interruptions, regardless of executor capability.

**Plan body must not include** (at strategic/tactical levels):
- full code listings (use contracts instead)
- step-by-step TDD for every micro-action
- detailed file lists for every action
- exact shell commands for every step

The plan defines delivery structure. The executor defines execution structure.
The plan is a draft for mandatory `/cp-plan-review` — it is not execution-ready until reviewed, fixed, and revalidated.

### Plan Batching

For medium and large tasks, split the plan body into batch files to keep executor context compact and improve review/fix precision.

**Structure:**
- `<task-slug>.plan.md` — master file with header, batch index, and dependency graph
- `<task-slug>.plan-batch-NN.md` — one file per batch

**Master file batch index:**
```markdown
## Batch Index
| Batch | Stage | Depends on | Status |
|-------|-------|------------|--------|
| 01 | <stage name> | — | pending |
| 02 | <stage name> | 01 | pending |
| 03 | <stage name> | 01, 02 | pending |
```

**Batching rules:**
- **small tasks** — single `plan.md`, no batches
- **medium tasks** — `plan.md` + 2-3 batch files
- **large tasks** — `plan.md` + N batch files + explicit dependency graph
- each batch is a self-contained deliverable with its own verification criteria
- executor loads only the current batch, not the whole plan
- independent batches may be parallelized
- batch status is updated in the master file as execution progresses

**Benefits:**
- executor context stays compact — critical for weaker models and long tasks
- review/fix operates per batch — more precise findings, faster fixes
- resume is trivial — pick up from the next pending batch
- interrupted sessions lose minimal work

## Rules Compliance Pre-check

Before considering the plan ready, verify it against the project rules collected during context readiness:
- check that the plan does not contradict any rule (e.g. migration strategy, test commands, code style constraints, commit policy)
- check that verification commands match what project rules prescribe
- check that constraints in the plan header reflect actual project constraints

If conflicts are found, fix them in the plan before proceeding. This pre-check reduces the number of findings in `/cp-plan-review` and prevents critical rule violations from reaching the review stage.

## Workflow Log

{{@include:_shared/workflow-log.md}}

## Language Policy

- Internal reusable instructions remain in English
- User-facing updates must follow active client or agent language rules
- Project-facing artifacts must follow explicit project language rules first, then active agent rules, then English as fallback
- `workflow.md` is always English

## User-Facing Rules

- Show command names as `/cp-plan`, `/cp-plan-review`, `/cp-execute`
- Use display names such as `plan writing`, `plan review`, `execution`
- Do not expose internal technical stage ids, prompt file names, or hidden agent role names unless technically necessary

## Automatic Workflow Continuation

After the plan is written and the rules pre-check passes, automatically invoke `/cp-plan-review` ({{INVOKE_SKILL}}). Do not ask the user to run it manually.

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects plan structure
- required tools, access, or dependencies are missing

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Start writing the plan before context readiness gate passes** — missing context leads to review findings that could have been prevented
- **Include full code listings in strategic/tactical plans** — use contracts (interfaces, signatures, pseudocode) instead
- **Skip the rules compliance pre-check** — every plan must be validated against project rules before handoff
- **Hardcode executor assumptions** — adapt granularity to the executor tier specified in the design
- **Create unbatched plans for medium/large tasks** — batch files keep executor context compact and improve review precision

## Completion Criteria

This command is complete when:
- context readiness gate passed
- commit strategy determined
- plan written with correct granularity for executor tier
- rules compliance pre-check passed
- `/cp-plan-review` has been invoked (or handed off to a new session)

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
