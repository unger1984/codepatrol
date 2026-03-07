---
name: cp-idea
description: "Use for any new task: brainstorming ideas, exploring approaches, designing solutions, and creating implementation plans"
---

# /cp-idea

Use this command as the default entry point for a new workflow run.

## Model Policy

This command performs clarification, research, design, and planning. The stages have different reasoning demands:

| Stage | Reasoning load | Execution |
|-------|---------------|-----------|
| **Clarification** | Understanding gaps, formulating questions | Orchestrator (needs user dialog) |
| **Research** | Reading + summarizing | Dispatch to research subagent (default tier) |
| **Approach options** | Architecture reasoning, trade-offs | Orchestrator (heavy reasoning) |
| **Solution outline** | Iterative refinement with user | Orchestrator |
| **Research refresh** | Targeted re-check | Dispatch to research subagent (default tier) |
| **Design** | Producing design.md | Orchestrator (heavy reasoning) |
| **Plan** | Decomposition, dependencies, verification | Orchestrator (heavy reasoning) |

**Research as subagent:** dispatch research to a subagent using the researcher prompt (see Research section). The subagent reads project rules, docs, code, and optionally web sources, then returns a structured summary. The orchestrator uses this summary for all subsequent stages — no need to re-read the codebase or rules directly.

{{DISPATCH_AGENT}}

**Ceiling rule:** subagents cannot use a more capable model than the orchestrator session.

**User override:** if project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers, use it.

**Escalation:** if the research subagent fails, re-dispatch at the next tier up. Maximum one escalation. If the ceiling tier fails, the orchestrator runs research directly.

**Recommendation:** clarification, approach, design, and plan stages require strong reasoning. It is recommended to run `/cp-idea` on the most capable available model. If the current model may be too weak for quality design work, warn the user and suggest switching before proceeding.

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

## Progress Tracking (mandatory)

Before starting work, you MUST create {{PROGRESS_TOOL}} items for each workflow stage.
Mark each as `in_progress` when entering a stage and `completed` when stage criteria are met.
This provides visual progress to the user.

Required items:
- [ ] Clarification
- [ ] Research
- [ ] Approach options
- [ ] Solution outline
- [ ] Research refresh
- [ ] Design
- [ ] Handoff to /cp-plan

## No-argument behavior

When invoked without arguments:
1. Check `.ai/tasks/` for unfinished workflow tasks (see §1 below).
2. If no unfinished tasks and no task description provided, ask the user what task they want to work on. Use `{{ASK_USER}}` if available.

Do not start work without knowing the task objective.

## Goals

- Check for unfinished workflow tasks before creating a new one
- Start from clarification, then research with specific scope
- Drive the flow: clarification -> research -> approach options -> design ready
- Keep internal stage identifiers and internal agent names hidden from users
- Follow active client or agent language rules for user-facing communication
- Do not take actions the user did not request. Do not guess intent when multiple interpretations exist
- Ask first, act second. A clarifying question is always cheaper than a wrong action

## Required Behavior

### 1. Warn About Unfinished Tasks

Before creating a new task, inspect `.ai/tasks/` for workflow files with `Status: in-progress`.

If unfinished tasks exist:
- show a warning
- list task id, current stage display name, and overall status
- offer exactly two paths:
  - resume one of the unfinished tasks — invoke `/cp-resume` directly ({{INVOKE_SKILL}})
  - ignore the warning and create a new workflow task

When the user chooses to resume, invoke `/cp-resume` immediately. Do not tell the user to run it manually.

Do not silently create a new task when unfinished work already exists.

### 1b. Create Task Folder

When starting a new task, create the task directory and workflow file:
- `.ai/tasks/<YYYY-MM-DD-HHMM-task-slug>/`
- `<task-slug>.workflow.md` inside it

Example: `.ai/tasks/2026-03-06-1420-auth-refactor/auth-refactor.workflow.md`

Use `mkdir -p` to create the directory. This is idempotent — do not check existence separately or ask for permission to create `.ai/` directories.

The task slug should be short, descriptive, and derived from the user's request.
Before generating the folder name, run `date +%H%M` to get the current time. Use the real output in the HHMM part. Never hardcode or guess the time.
Design and plan files are created later when those stages are reached.

### 1c. Workflow File Format

`workflow.md` is always written in English regardless of project language rules.

Required sections:
- **Task** — objective and scope
- **Status** — `in-progress` or `done`
- **Artifacts** — links to design, plan, and report files
- **Stage Tracking** — each stage with status (`open`, `in-progress`, `done`, `skipped`):
  - Clarification, Research, Approach options, Solution outline, Research refresh
  - Design, Plan, Plan review, Plan-review fixes, Plan revalidation
  - Execution, Code review, Code-review fixes, AI docs update
- **Decisions** — key execution decisions
- **Notes** — minimal notes sufficient to resume in a new session
- **Log** — chronological activity log (see Workflow Log below)

### 2. Clarify First

Before any research, understand what the user wants through dialogue.

Ask one question at a time. Wait for the response before asking the next one.

Rules:
- Prefer multiple choice questions — easier for the user to answer and keeps scope focused
- Always include an "other" option {{ASK_USER_OTHER_NOTE}}
- Open-ended questions are fine when the answer space is genuinely unknown
- Focus on requirements, intent, constraints, and scope — not on implementation details (those come after research)
- Infer obvious intent, but ask when ambiguity would change scope, architecture, or execution strategy
- For small tasks: 1-2 questions max, then move on

When asking, use `{{ASK_USER}}` if available. Otherwise ask in chat.

### 2b. Classify Task Complexity

After clarification, internally classify the task as small, medium, or large.

- **small** — single-file or narrow-scope change, minimal design needed, lightweight workflow
- **medium** — multiple files or modules, explicit design and plan needed, full workflow
- **large** — cross-cutting change, detailed design with diagrams, full workflow with checkpoints

Adapt workflow depth to complexity. Do not skip stages arbitrarily — base the decision on scope and risk.

**Dialogue depth by complexity:**

| Aspect | small | medium | large |
|--------|-------|--------|-------|
| Questions | 1-2 max, infer the rest | Full discipline, one at a time | Full discipline, one at a time |
| Approaches | Single recommendation with brief rationale | 2-3 with trade-offs, lead with recommendation | 2-3 with structured comparison, lead with recommendation |
| Outline | Few sentences, still requires confirmation | Section-by-section with validation | Section-by-section with validation + diagrams |

### 3. Research (scoped)

After clarification, dispatch a research subagent to gather project context for the specific scope identified during clarification.

{{DISPATCH_RESEARCHER}}

**Researcher prompt:**

{{@include:_shared/researcher.md}}

**Query construction:** based on clarification results, formulate a specific research query. Include:
- what the task is about
- which areas of the codebase to investigate
- what rules and constraints are relevant
- scope hints: specific paths, modules, or file patterns if known

The orchestrator uses the research summary for all subsequent stages without re-reading the codebase.

### 4. Offer Realistic Approaches

If multiple viable approaches exist:
- Lead with your recommended option and explain WHY
- Then present 1-2 alternatives with trade-offs
- Be explicit about what you'd lose and gain with each option

For small tasks: a single recommendation with brief rationale is sufficient.
For medium and large tasks: make the trade-off comparison structured and explicit.

Do not present options without a recommendation. The user needs your architectural judgment, not just a menu.

### 4b. Iterative Solution Outline

After the user chooses a direction, form an initial solution outline.

Present the outline in logical sections. After each section, ask whether it looks right before moving on. Scale section depth to complexity: 2-3 sentences (~50 words) if straightforward, up to 200-300 words if nuanced or architecturally significant.

The user may refine scope, approach, constraints, or request additional options multiple times.
After each refinement:
- update the outline
- show what changed
- update trade-offs if needed

### Anti-Pattern: "This Is Too Simple To Skip"

Every task goes through outline confirmation — a todo list, a single-function utility, a config change. "Simple" tasks are where unexamined assumptions cause the most wasted work. The outline may be compact, but skipping confirmation means skipping the only checkpoint where the user can catch a wrong assumption before it becomes a wrong design.

<HARD-GATE>
Do NOT suggest moving to design until the user explicitly confirms the full solution outline. This applies to ALL tasks regardless of complexity. For small tasks, the outline may be compact, but explicit confirmation is still required.

**Why this gate exists:** design and plan are expensive to redo. A 10-second confirmation prevents a 10-minute rewrite. The model's confidence in understanding the task is not a substitute for the user's confirmation.
</HARD-GATE>

### 5. Drive Design Readiness

Do not jump to implementation.

The expected progression is:
1. clarification
2. research (scoped)
3. approach options
4. iterative solution outline discussion
5. research refresh (if scope changed since initial research)
6. design

Only suggest moving to design when research and discussion are sufficient. Once design is approved, hand off to `/cp-plan`.

### 5b. Research Refresh

Research refresh is mandatory before design generation. Dispatch it to a research subagent.

{{DISPATCH_RESEARCHER}}

**Query construction for refresh:** based on the chosen approach and confirmed outline, formulate a targeted query. Include:
- chosen approach and rationale
- confirmed scope
- specific areas to re-check (things that became important after approach was chosen)
- project rules summary from initial research (for cross-reference)

The refresh is not a full repeat of research — it is a targeted re-sync before design. If the scope has not changed materially since initial research, the refresh can be narrower.

The subagent must return:
- **confirmed** — what holds true
- **conflicts** — what contradicts the chosen approach
- **new details** — what was discovered that affects design

### 5c. Design File Format

One design file per workflow task: `<task-slug>.design.md` inside the task folder.
The file is edited iteratively — no separate versions within one task.

Design file must include:
- task objective
- research summary
- constraints and relevant rules
- considered approaches with trade-offs
- chosen approach and rationale
- solution outline
- execution strategy (see below)
- impact analysis
- assumptions and open questions
- diagrams where they genuinely help

**Execution strategy section** must specify:
- **Plan generation:** workflow skills chain (e.g. `/cp-idea` → `/cp-plan-review` → `/cp-plan-fix`)
- **Execution:** target skill and model tier (e.g. `/cp-execute` on Opus)
- **Granularity implications:** how the executor tier affects plan detail level (see Plan Granularity by Executor Tier)

Default format: Markdown with Mermaid diagrams (DFD, Sequence, module relationships).
Use C4-lite when it helps. Project rules and conventions override these defaults.

Role: act as senior software architect.
Design based on research and actual project structure, not ideal architecture in a vacuum.
Do not jump to plan or implementation. Do not silently ignore project rules.

**Design commit checkpoint:**
After the design file is written and approved, commit it as a separate checkpoint — this fixes the point of agreement before planning begins.
- If project rules explicitly prohibit auto-commits, do not commit without user command.
- Otherwise, ask the user whether to commit the design file now. Use `{{ASK_USER}}` if available.

### 5d. Handoff to Plan Writing

After the design is approved and committed, the next step is plan writing via `/cp-plan`.

Plan file format, granularity, batching, commit strategy, and rules compliance are defined in `/cp-plan`.

## Workflow Log

{{@include:_shared/workflow-log.md}}

## Language Policy

- Internal reusable instructions remain in English
- User-facing updates must follow active client or agent language rules
- Project-facing artifacts must follow explicit project language rules first, then active agent rules, then English as fallback
- `workflow.md` is always English

## User-Facing Rules

- Show command names as `/cp-idea`, `/cp-resume`, `/cp-plan-review`, `/cp-execute`, `/cp-docs`
- Use display names such as `research`, `clarification`, `plan review`, `execution`, `AI docs update`
- Do not expose internal technical stage ids, prompt file names, or hidden agent role names unless technically necessary

### Automatic Workflow Continuation

After the design is approved and committed, automatically invoke `/cp-plan` ({{INVOKE_SKILL}}). Do not ask the user to run it manually.

The full auto-continuation chain within a workflow task is:
1. design approved → invoke `/cp-plan`
2. `/cp-plan` writes plan → invoke `/cp-plan-review`
3. `/cp-plan-review` saves report → invoke `/cp-plan-fix`
4. `/cp-plan-fix` completes → handoff decision (defined in `/cp-plan-fix`)

Manual invocation is only suggested when handing off to a new session.

## Dialogue Principles

- **One question at a time** — do not overwhelm with multiple questions in one message
- **Multiple choice preferred** — easier to answer, keeps scope tight
- **Recommend, don't just list** — always lead with your recommendation and reasoning
- **Incremental validation** — present outline in sections, confirm each before moving on
- **YAGNI** — actively remove unnecessary complexity from all designs
- **Ask first, act second** — a clarifying question is always cheaper than a wrong action

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects design direction
- required tools, access, or dependencies are missing
- research returns conflicting or insufficient information for a design decision

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Skip outline confirmation** — even for "simple" tasks, the user must confirm the outline before design begins
- **Jump to implementation** — this skill produces a design, not code. Do not write code, create files outside `.ai/`, or start implementation
- **Ask multiple questions at once** — one question per message, wait for the answer
- **Present options without a recommendation** — always lead with your judgment, then alternatives
- **Run research without scope** — always scope research to the clarified task, never bulk-read the entire codebase
- **Re-read the same files after research** — the orchestrator works from the research summary, not from raw file reads
- **Silently create a new task when unfinished work exists** — always warn and offer to resume first

## Completion Criteria

This command is complete when:
- the workflow task exists
- clarification and research are captured
- the current design state is approved and committed (or commit deferred per project rules)
- `/cp-plan` has been invoked (or handed off to a new session)

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
