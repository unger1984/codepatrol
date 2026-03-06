---
name: cpreview
description: Orchestrated code review with mandatory compliance pass before quality pass
---

# /cpreview

Review implementation with a workflow-first review model.

## Supported Scope Modes

- current workflow task
- current working tree
- staged changes
- committed branch diff
- branch-vs-branch diff
- pull request or merge request diff
- entire project
- explicit file or directory paths

If scope is ambiguous or empty, ask before reviewing.

## Research Before Review

Before starting review:
- if `.ai/docs/README.md` exists, read it and only relevant domain/shared docs
- if review is task-scoped, read task artifacts (workflow.md, design, plan)
- identify documented exceptions, accepted trade-offs, and constraints
- then read the relevant code

For the compliance pass, mandatory sources are:
- `workflow.md` if review is within a workflow task
- approved design
- current plan
- relevant project rules and accepted constraints

## Review Order

The order is mandatory:
1. compliance pass
2. quality pass

### Compliance Pass

Check that the implementation matches:
- approved design
- current plan
- workflow decisions
- project rules
- documented constraints

Catch missing required work, scope creep, or violations of explicit intent before deeper quality review starts.

### Quality Pass

Review engineering quality after compliance is acceptable:
- architecture and maintainability
- conventions and local code quality
- testing and verification adequacy
- security and reliability risks

## Execution Model

- **simple scopes** — the orchestrator runs both compliance and quality passes directly
- **medium and large scopes** — the orchestrator may:
  - dispatch a dedicated compliance reviewer subagent
  - dispatch quality-oriented reviewer agents by dimension (architecture, testing, security, conventions)
- all findings from subagents must be normalized into one report

The orchestrator must not:
- report as a defect something already documented as an accepted constraint
- run a broad noisy review without proper scoping
- treat every deviation from plan/design as an error without evaluating context

## Reports

Workflow-task code review reports are always saved under:
- `.ai/tasks/<task>/reports/<timestamp>-<task-slug>.review.report.md`

Ad hoc reviews save under:
- `.ai/reports/<timestamp>-<scope>.review.report.md`

Each finding must include:
- severity
- finding type: `compliance` or `quality`
- recommended resolution
- status (`open`, `done`, `skipped`)
- resolved via
- resolution notes

A finding cannot be marked `done` without verification evidence that the risk is actually resolved.

## Handoff

After the report is saved, the next fix command is `/cpfix`.

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.

## Completion Criteria

This stage is complete when the compliance pass and quality pass are both finished and the report is saved.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
