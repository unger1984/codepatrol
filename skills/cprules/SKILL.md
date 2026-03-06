---
name: cprules
description: Analyze recurring workflow results and propose project rule improvements with user approval before apply
---

# /cprules

Use this command to improve project rules after enough evidence exists.

## Purpose

Analyze completed tasks, review reports, and repeated fix patterns to find:
- missing project rules
- weak or outdated rules
- rules that exist but failed to prevent recurring problems

## Two-Phase Workflow

1. Analyze and propose changes in chat
2. Apply only the user-approved subset

## Rules For Applying Changes

- never modify project rules without explicit user approval
- do not create rule churn from one-off issues
- explain why each proposed rule is worth adding or changing
- prefer updating an existing rule file over creating new files unless a new file is clearly justified

## Inputs

Review only the relevant evidence:
- completed workflow artifacts
- review reports
- existing rule files
- `.ai/docs/README.md` and related docs when they exist and affect rule interpretation

## Output

Present:
- recurring pattern
- recommended rule change
- rationale
- expected benefit

After approval, apply the selected changes and summarize what changed.

## Completion Criteria

This command is complete when proposals are delivered, and any applied changes reflect explicit user approval.
