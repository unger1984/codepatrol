---
name: cpatrol
description: Workflow-first entry command for research, clarification, design, and plan setup
---

# /cpatrol

Use this command as the default entry point for a new workflow run.

## Goals

- Check for unfinished workflow tasks before creating a new one
- Start from project context and research, not implementation
- Drive the flow: research -> clarification -> approach options -> design -> plan ready
- Keep internal stage identifiers and internal agent names hidden from users
- Follow active client or agent language rules for user-facing communication

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

### 2. Start With Research

Research is mandatory.

Always begin context discovery from `.ai/docs/README.md`, then read only the docs and code needed for the current task. Do not bulk-read the repository.

Research must produce usable output:
- key findings
- confirmed facts
- assumptions
- open questions

### 3. Clarify Only What Matters

Infer intent when safe. Ask the user only when ambiguity would change scope, architecture, or execution strategy.

When asking, prefer concrete options over vague questions. If `{{ASK_USER}}` is available in the current platform, use it. Otherwise ask in chat.

### 4. Offer Realistic Approaches

If multiple viable approaches exist:
- present 2-3 options
- explain trade-offs briefly
- recommend one approach

For small tasks, keep this lightweight. For medium and large tasks, make the trade-off discussion explicit.

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

## Language Policy

- Internal reusable instructions remain in English
- User-facing updates must follow active client or agent language rules
- Project-facing artifacts must follow explicit project language rules first, then active agent rules, then English as fallback
- `workflow.md` is always English

## User-Facing Rules

- Show command names as `/cpatrol`, `/cpresume`, `/cpplanreview`, `/cpexecute`, `/cpdocs`
- Use display names such as `research`, `clarification`, `plan review`, `execution`, `AI docs update`
- Do not expose internal technical stage ids, prompt file names, or hidden agent role names unless technically necessary

## Completion Criteria

This command is complete for the current stage when:
- the workflow task exists
- research and clarification are captured
- the current design state is approved or explicitly accepted for continuation
- the plan is ready to enter `/cpplanreview`
