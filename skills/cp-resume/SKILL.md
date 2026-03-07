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
- **continue now** — invoke the recommended next command directly (Use the Skill tool to invoke the target skill directly.)
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

### Workflow Log (mandatory within a workflow task)

When working within a workflow task, append entries to the `## Log` section of `workflow.md` at these points:
- **skill invoked** — which skill started and how (auto-invoked, user-invoked, resumed)
- **subagent dispatched** — role and brief result (e.g. "research subagent → 5 findings, 2 open questions")
- **question asked** — brief question and user's answer
- **skill completed** — brief outcome (e.g. "plan ready, 0 rule violations" or "3 critical, 2 important findings")
- **blocker hit** — what blocked and how it was resolved

Log format — append one line per event:
```
- `HH:MM` **/skill** — action → result
```

Keep entries to one line each. Do not log internal reasoning, full agent context, or file contents.
Use `date +%H%M` for the timestamp. Do not guess the time.

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
