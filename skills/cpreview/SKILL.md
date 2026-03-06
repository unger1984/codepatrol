---
name: cpreview
description: Orchestrated code review with mandatory compliance pass before quality pass
---

# /cpreview

Review implementation with a workflow-first review model.

## Progress Tracking (mandatory)

Before dispatching reviewers, you MUST create TodoWrite items for all review passes.
Mark each as `in_progress` when dispatching and `completed` when results are collected.
This provides visual progress to the user.

Required items:
- [ ] Compliance pass
- [ ] Architecture review
- [ ] Security review
- [ ] Testing review
- [ ] Conventions review
- [ ] Report generation

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

## Scope Interpretation

### Natural language mapping

| User says | Interpreted as |
|-----------|---------------|
| "весь проект", "all code", "entire project", "everything" | all source files in project |
| "current branch", "branch vs main" | committed diff vs main |
| "uncommitted", "working changes" | uncommitted changes |
| "branch X vs Y" | diff between branches |
| "PR", "pull request" | PR diff |
| specific file or directory paths | those paths only |
| no argument, active workflow task | task-scoped review |

### When in doubt — ask, do not guess

If you cannot confidently determine scope, OR if the determined scope is empty — stop and ask with concrete options. Use `AskUserQuestion` if available.

Never guess scope. Never review 0 files silently. Wrong scope = wasted review.
Do not run diffs, merge branches, or take any destructive action unless explicitly requested.

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
- Launch reviewers in parallel using Agent tool with `subagent_type="code-reviewer"` and `run_in_background=true`. Send all Agent calls in a single message for true parallelism.
- all findings from subagents must be normalized into one report

The orchestrator must not:
- report as a defect something already documented as an accepted constraint
- run a broad noisy review without proper scoping
- treat every deviation from plan/design as an error without evaluating context

## Reports

Workflow-task code review reports are always saved under:
- `.ai/tasks/<task>/reports/YYYY-MM-DD-HHMM-<task-slug>.review.report.md`

Ad hoc reviews save under:
- `.ai/reports/YYYY-MM-DD-HHMM-<scope>.review.report.md`

Use real creation time in the filename.
Example: `.ai/tasks/2026-03-06-1420-auth-refactor/reports/2026-03-06-1540-auth-refactor.review.report.md`

A finding cannot be marked `done` without verification evidence that the risk is actually resolved.

## Report Format

Structure the report as:

```markdown
## Code Review Report

### Summary
- Scope: N files (scope description)
- Critical: N | Important: N | Minor: N
- Assessment: NEEDS_CHANGES | APPROVED | APPROVED_WITH_NOTES

### Critical Issues
1. [CATEGORY] `file:line` — description
   **Finding type:** compliance | quality
   **Fix:** concrete solution with code snippet where applicable
   **Status:** open
   **Resolved via:**
   **Resolution notes:**

### Important Issues
(same format)

### Minor Issues
(same format)

### Strengths
What was done well.
```

Rules:
- every issue MUST include a Fix field with a concrete solution — an issue without a Fix is useless
- group by severity: Critical → Important → Minor
- assessment: NEEDS_CHANGES if any Critical or open compliance findings, APPROVED_WITH_NOTES if only Important/Minor quality findings, APPROVED if no issues
- deduplicate: if two reviewers found the same issue, keep one with both tags
- severity disagreement between reviewers: take the highest
- when aggregating subagent results, always preserve Fix and code snippets from subagent output

## Handoff

After the report is saved, the next fix command is `/cpfix`. Use the Skill tool to invoke the target skill directly.

## Scope Detection Commands

Default (no args) — committed diff vs main:
```bash
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff --name-only ${MAIN_BRANCH}...HEAD
```

Uncommitted changes:
```bash
(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u
```

Entire project — detect primary language(s) from existing files, collect all source files. Exclude: build output, dependencies, generated files, lock files.

Specific paths — use as-is. If a directory — find all source files inside it.

For file discovery, use Glob, Grep, or MCP filesystem tools if available. Do not fall back to shell commands (find, grep) unless no dedicated tool is available.

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `AskUserQuestion` if available on the current platform.

## Completion Criteria

This stage is complete when the compliance pass and quality pass are both finished and the report is saved.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
