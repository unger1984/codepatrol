---
name: cpatrol
description: Workflow-first entry command for research, clarification, design, and plan setup
---

# /cpatrol

Use this command as the default entry point for a new workflow run.

## Progress Tracking (mandatory)

Before starting work, you MUST create TodoWrite items for each workflow stage.
Mark each as `in_progress` when entering a stage and `completed` when stage criteria are met.
This provides visual progress to the user.

Required items:
- [ ] Research
- [ ] Clarification
- [ ] Approach options
- [ ] Solution outline
- [ ] Research refresh
- [ ] Design
- [ ] Plan

## Goals

- Check for unfinished workflow tasks before creating a new one
- Start from project context and research, not implementation
- Drive the flow: research -> clarification -> approach options -> design -> plan ready
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
  - resume one of the unfinished tasks with `/cpresume`
  - ignore the warning and create a new workflow task

Do not silently create a new task when unfinished work already exists.

### 1b. Create Task Folder

When starting a new task, create the task directory and workflow file:
- `.ai/tasks/<YYYY-MM-DD-HHMM-task-slug>/`
- `<task-slug>.workflow.md` inside it

Example: `.ai/tasks/2026-03-06-1420-auth-refactor/auth-refactor.workflow.md`

If `.ai/tasks/` does not exist, create it.

The task slug should be short, descriptive, and derived from the user's request.
Use real creation date and time (HHMM) in the folder name.
Design and plan files are created later when those stages are reached.

### 1c. Workflow File Format

`workflow.md` is always written in English regardless of project language rules.

Required sections:
- **Task** — objective and scope
- **Status** — `in-progress` or `done`
- **Artifacts** — links to design, plan, and report files
- **Stage Tracking** — each stage with status (`open`, `in-progress`, `done`, `skipped`):
  - Research, Clarification, Approach options, Research refresh
  - Design, Plan, Review plan, Fix review plan, Plan revalidation
  - Execute, Review code, Fix review code, Update AI docs
- **Decisions** — key execution decisions
- **Notes** — minimal notes sufficient to resume in a new session

### 2. Start With Research

Research is mandatory.

If `.ai/docs/README.md` exists, begin context discovery from it, then read only the docs and code needed for the current task.
If it does not exist, begin research directly from project rules, CLAUDE.md/AGENTS.md, and the actual codebase. Do not require `.ai/` to exist.
Do not bulk-read the repository.
For file discovery, use Glob, Grep, or MCP filesystem tools if available. Do not fall back to shell commands (find, grep) unless no dedicated tool is available.

Research must produce usable output:
- key findings
- confirmed facts
- assumptions
- open questions

### 2b. Classify Task Complexity

After research, internally classify the task as small, medium, or large.

- **small** — single-file or narrow-scope change, minimal design needed, lightweight workflow
- **medium** — multiple files or modules, explicit design and plan needed, full workflow
- **large** — cross-cutting change, detailed design with diagrams, full workflow with checkpoints

Adapt workflow depth to complexity. Do not skip stages arbitrarily — base the decision on research, scope, and risk.

### 3. Clarify Only What Matters

Infer intent when safe. Ask the user only when ambiguity would change scope, architecture, or execution strategy.

When asking, prefer concrete options over vague questions. If `AskUserQuestion` is available in the current platform, use it. Otherwise ask in chat.

### 4. Offer Realistic Approaches

If multiple viable approaches exist:
- present 2-3 options
- explain trade-offs briefly
- recommend one approach

For small tasks, keep this lightweight. For medium and large tasks, make the trade-off discussion explicit.

### 4b. Iterative Solution Outline

After the user chooses a direction, form an initial solution outline.

The user may refine scope, approach, constraints, or request additional options multiple times.
After each refinement:
- update the outline
- show what changed
- update trade-offs if needed

Only suggest moving to design after the user confirms the solution outline.

### 5. Drive Design And Plan Readiness

Do not jump to implementation.

The expected progression is:
1. research
2. clarification
3. approach options
4. iterative solution outline discussion
5. research refresh if needed
6. design
7. plan

Only suggest moving to design when research and discussion are sufficient. Only mark plan ready when the current plan is ready for `/cpplanreview`.

### 5b. Research Refresh

Research refresh is mandatory before design generation.

It is required after:
- initial research
- clarification
- approach discussion
- direction choice
- solution outline iterations

It must:
- re-check the chosen approach against the actual codebase
- confirm final scope
- verify no conflicts with docs and project rules
- gather details that became important only after the approach was chosen

This is not a full repeat of research — it is a targeted re-sync before design.

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
- impact analysis
- assumptions and open questions
- diagrams where they genuinely help

Default format: Markdown with Mermaid diagrams (DFD, Sequence, module relationships).
Use C4-lite when it helps. Project rules and conventions override these defaults.

Role: act as senior software architect.
Design based on research and actual project structure, not ideal architecture in a vacuum.
Do not jump to plan or implementation. Do not silently ignore project rules.

### 5d. Plan File Format

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

**Plan body must not include:**
- full code listings
- step-by-step TDD for every micro-action
- detailed file lists for every action
- exact shell commands for every step

The plan defines delivery structure. The executor defines execution structure.
The plan is a draft for mandatory `/cpplanreview` — it is not execution-ready until reviewed, fixed, and revalidated.

### 5e. Commit Strategy

Before writing the plan, determine the commit strategy.

If project rules or CLAUDE.md/AGENTS.md define a commit strategy, use it.
Otherwise, ask the user. Use `AskUserQuestion` if available.

Supported strategies:
- no intermediate commits
- commit per stage
- commit per step
- custom strategy for the specific task

The chosen strategy affects plan structure, checkpoints, execution safety, parallelization, and rollback safety.

## Language Policy

- Internal reusable instructions remain in English
- User-facing updates must follow active client or agent language rules
- Project-facing artifacts must follow explicit project language rules first, then active agent rules, then English as fallback
- `workflow.md` is always English

## User-Facing Rules

- Show command names as `/cpatrol`, `/cpresume`, `/cpplanreview`, `/cpexecute`, `/cpdocs`
- Use display names such as `research`, `clarification`, `plan review`, `execution`, `AI docs update`
- Do not expose internal technical stage ids, prompt file names, or hidden agent role names unless technically necessary

### Session Mode Heuristic

After plan is ready, recommend whether to continue execution in the current session or hand off to a new one.

Prefer current session when:
- context is still fresh and compact
- the task is small enough
- trade-offs are already closed

Prefer new session when:
- task artifacts are self-contained
- upcoming work is long or multi-stage
- current context is already heavy

Provide a reasoned recommendation, but leave the final choice to the user.
For a new session, provide a short handoff command referencing the task artifact path.

## Completion Criteria

This command is complete for the current stage when:
- the workflow task exists
- research and clarification are captured
- the current design state is approved or explicitly accepted for continuation
- the plan is ready to enter `/cpplanreview`

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
