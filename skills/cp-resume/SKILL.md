---
name: cp-resume
description: Use to continue unfinished work from a previous session
---

# /cp-resume

Resume work from existing workflow artifacts instead of reconstructing context from memory.

## Accepted Inputs

- a workflow artifact path
- a task directory
- `workflow.md`
- `design.md`
- `plan.md`
- a report file inside `reports/`

If no argument is provided, find resumable tasks under `.ai/tasks/` and ask the user which one to continue. Use `AskUserQuestion` if available on the current platform.

## Resume Process

### 1. Load Artifacts

Collect the minimum set of artifacts needed to continue:
- `<task-slug>.workflow.md`
- `<task-slug>.design.md` if present
- `<task-slug>.plan.md` if present
- open review reports if present

If `workflow.md` is missing or unparseable, report the issue to the user and offer options: start fresh with `/cp-idea`, or manually specify the phase to resume from. Use `AskUserQuestion` if available.

If `.ai/docs/README.md` exists, start additional docs research from it. If it does not exist, skip docs-based research.

### 2. Detect The Current Phase

Use workflow state and artifact evidence to detect the current phase automatically.

Map internal progress to user-facing display names:
- `research`
- `clarification`
- `approach options`
- `solution outline`
- `research refresh`
- `design`
- `plan`
- `plan review`
- `plan-review fixes`
- `plan revalidation`
- `execution`
- `code review`
- `code-review fixes`
- `AI docs update`

Prefer the latest unfinished mandatory stage. If reports show open findings, resume from the matching fix stage instead of skipping ahead.

### 3. Reconstruct Handoff State

Summarize:
- task objective
- current status
- last completed verified stage
- open blockers
- recommended next command

Use artifact evidence, not assumptions.

### 4. Continue The Workflow

After presenting the handoff state, offer two paths:
- **continue now** — invoke the recommended next command (Use the Skill tool to invoke the target skill directly.)
- **hand off to a new session** — provide the command with the task artifact path for the user to run later

When the user chooses to continue, invoke the command immediately. Do not tell the user to run it manually.

## Resumability Rules

- Reports are audit artifacts and remain append-only except for tracking fields that the workflow explicitly mutates
- A task stays resumable while `Status: in-progress`
- Resume must preserve display names for the user even if internal stage identifiers differ

## Examples

- `/cp-resume .ai/tasks/2026-03-06-1420-ai-workflow/`
- `/cp-resume .ai/tasks/2026-03-06-1420-ai-workflow/ai-workflow.workflow.md`
- `/cp-resume .ai/tasks/.../reports/2026-03-06-1540-ai-workflow.plan-review.report.md`

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
- workflow.md is missing or unparseable and phase cannot be detected
- multiple resumable tasks exist and auto-selection is ambiguous
- artifact state is inconsistent (e.g. design exists but workflow.md shows an earlier stage)
- required tools, access, or dependencies are missing

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `AskUserQuestion` if available on the current platform.

## Anti-patterns

Do NOT:
- **Guess the current phase** — use artifact evidence, not assumptions
- **Skip loading workflow.md** — it is the primary source of truth for resume
- **Start work without presenting the handoff state** — always show the user what was found before acting
- **Modify task artifacts during resume** — this skill reads and routes, it does not edit
- **Assume context from a previous session** — reconstruct everything from artifacts

## Completion Criteria

This command is complete when the recommended next command has been invoked or the user has received a handoff command for a new session.
