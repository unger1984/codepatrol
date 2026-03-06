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

- simple scopes may keep the compliance pass in the main orchestrator
- medium and large scopes may dispatch specialized reviewers
- findings must be normalized into one report

## Reports

Workflow-task code review reports are always saved under:
- `.ai/tasks/<task>/reports/<timestamp>-<task-slug>.review.report.md`

Ad hoc reviews save under:
- `.ai/reports/<timestamp>-<scope>.review.report.md`

Each finding must include:
- severity
- finding type: `compliance` or `quality`
- recommended resolution
- status
- resolved via
- resolution notes

## Handoff

After the report is saved, the next fix command is `/cpfix`.

## Completion Criteria

This stage is complete when the compliance pass and quality pass are both finished and the report is saved.
