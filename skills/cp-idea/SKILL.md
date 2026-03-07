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

Launch reviewers in parallel using Agent tool with `run_in_background=true`. Send all Agent calls in a single message for true parallelism. Use the `model` parameter to set the model tier for each subagent.

**Ceiling rule:** subagents cannot use a more capable model than the orchestrator session.

**User override:** if project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers, use it.

**Escalation:** if the research subagent fails, re-dispatch at the next tier up. Maximum one escalation. If the ceiling tier fails, the orchestrator runs research directly.

**Recommendation:** clarification, approach, design, and plan stages require strong reasoning. It is recommended to run `/cp-idea` on the most capable available model. If the current model may be too weak for quality design work, warn the user and suggest switching before proceeding.

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

## Progress Tracking (mandatory)

Before starting work, you MUST create TodoWrite items for each workflow stage.
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
2. If no unfinished tasks and no task description provided, ask the user what task they want to work on. Use `AskUserQuestion` if available.

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
  - resume one of the unfinished tasks — invoke `/cp-resume` (Use the Skill tool to invoke the target skill directly.)
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
- Always include an "other" option (AskUserQuestion adds it automatically)
- Open-ended questions are fine when the answer space is genuinely unknown
- Focus on requirements, intent, constraints, and scope — not on implementation details (those come after research)
- Infer obvious intent, but ask when ambiguity would change scope, architecture, or execution strategy
- For small tasks: 1-2 questions max, then move on

When asking, use `AskUserQuestion` if available. Otherwise ask in chat.

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

Dispatch a research subagent using Agent tool with the researcher prompt from this skill.

**Researcher prompt:**

# Research Subagent

You are a research subagent. Your job is to find specific information and return a structured summary. You do not make decisions — you gather evidence.

## Available Sources

### Project sources

1. **Project rules** — ``.claude/rules/*.md` and `CLAUDE.md``
2. **Project documentation** — `.ai/docs/README.md` (if exists, use it as navigation hub; follow links to relevant docs only)
3. **Codebase** — files, configs, tests, scripts

For file discovery: For file discovery, use Glob, Grep, or MCP filesystem tools if available. Do not fall back to shell commands (find, grep) unless no dedicated tool is available.

### Web sources

For web research use WebSearch, WebFetch, or MCP Exa tools if available.

## Source Selection

Determine the right source from the query:

| Query pattern | Source |
|---|---|
| About this project, our code, how we do X | Project |
| External docs, library API, best practices, "how does X work" (not our code) | Web |
| Mixed — need both project context and external info | Project first, then web for gaps |
| Ambiguous | Project first; if insufficient, note the gap |

Do NOT go to web for questions answerable from the project. Do NOT dig through the codebase for questions about external tools/APIs.

## Research Protocol

1. Read the query and scope hints (if provided)
2. Select source(s) per the table above
3. For project research:
   - start from `.ai/docs/README.md` if it exists, follow navigation to relevant docs
   - read rules from ``.claude/rules/*.md` and `CLAUDE.md``
   - read only the code/files needed for the query — do not bulk-read
4. For web research:
   - search for the specific topic, not broad queries
   - prefer official documentation over blog posts
   - extract the relevant facts, not entire pages
5. If you cannot find what was asked — do not guess. Report the gap.

## Return Format

Return a structured summary in markdown:

```
## Research Summary

### Query
<the original query, restated>

### Findings
<what you found, organized by topic>

### Sources
<list of files read or URLs visited>

### Gaps
<what you could not find or verify>
<if web research might help, say so explicitly: "Web research recommended: <specific query>">
<if user clarification is needed, say so explicitly: "User clarification needed: <specific question>">
```

Adapt the Findings section to the query — there is no fixed schema. Use subsections if multiple topics were requested.

## Rules

- Return facts, not opinions
- Cite sources for every claim (file path and line, or URL)
- Do not read files outside the scope hints when scope hints are provided
- Do not modify any files — read only
- Keep the summary concise — the orchestrator works from this summary for all subsequent stages

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

Dispatch a research subagent using Agent tool with the researcher prompt from this skill.

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
- Otherwise, ask the user whether to commit the design file now. Use `AskUserQuestion` if available.

### 5d. Handoff to Plan Writing

After the design is approved and committed, the next step is plan writing via `/cp-plan`.

Plan file format, granularity, batching, commit strategy, and rules compliance are defined in `/cp-plan`.

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

After the design is approved and committed, automatically invoke `/cp-plan` (Use the Skill tool to invoke the target skill directly.). Do not ask the user to run it manually.

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

When asking the user, use `AskUserQuestion` if available on the current platform.

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
