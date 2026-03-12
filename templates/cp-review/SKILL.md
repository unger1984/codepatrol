---
name: cp-review
description: Use to review code changes for compliance and quality before merging
---

# /cp-review

Review implementation with a two-pass review model: compliance first, then quality.

## Progress Tracking (mandatory)

Before dispatching reviewers, you MUST create {{PROGRESS_TOOL}} items for all review passes.
Mark each as `in_progress` when dispatching and `completed` when results are collected.
This provides visual progress to the user.

Required items:
- [ ] Compliance pass
- [ ] Architecture review
- [ ] Security review
- [ ] Testing review
- [ ] Conventions review
- [ ] Compatibility review
- [ ] Report generation

## Supported Scope Modes

- current working tree
- staged changes
- committed branch diff
- branch-vs-branch diff
- pull request or merge request diff
- entire project
- explicit file or directory paths
- task-scoped (design + plan from `.ai/tasks/`)

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
| no argument | committed diff vs main |

### When in doubt — ask, do not guess

If you cannot confidently determine scope, OR if the determined scope is empty — stop and ask with concrete options. Use `{{ASK_USER}}` if available.

Never guess scope. Never review 0 files silently. Wrong scope = wasted review.
Do not run diffs, merge branches, or take any destructive action unless explicitly requested.

## Research Before Review

Before starting review:
- read project rules from `{{RULES_SOURCE}}`
- if `.ai/docs/README.md` exists, read it and only relevant domain/shared docs
- if a task folder exists in `.ai/tasks/` for the current work, read design and plan files
- identify documented exceptions, accepted trade-offs, and constraints
- then read the relevant code

For the compliance pass, mandatory sources are:
- project rules from `{{RULES_SOURCE}}`
- approved design (if exists in `.ai/tasks/`)
- current plan (if exists in `.ai/tasks/`)
- documented constraints and accepted trade-offs

## Review Order

The order is mandatory:
1. compliance pass
2. quality pass

### Compliance Pass

Check that the implementation matches:
- approved design (if exists)
- current plan (if exists)
- project rules
- documented constraints

Catch missing required work, scope creep, or violations of explicit intent before deeper quality review starts.

### Quality Pass

Review engineering quality after compliance is acceptable:
- architecture and maintainability
- conventions and local code quality
- testing and verification adequacy
- security and reliability risks
- compatibility and deprecated API usage

## Execution Model

- **simple scope** (≤5 reviewable files) — the orchestrator runs all passes directly
- **medium scope** (6–20 reviewable files) — the orchestrator may dispatch subagents at its discretion
- **large scope** (>20 reviewable files) — the orchestrator must dispatch subagents:
  - a dedicated compliance reviewer subagent
  - quality-oriented reviewer agents by dimension (architecture, testing, security, conventions, compatibility)
- {{DISPATCH_AGENT}}
- all findings from subagents must be normalized into one report

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

{{@include:_shared/subagent-limits.md}}

Starting tier by reviewer role:
- **Conventions / Compatibility** → fast
- **Architecture / Security / Testing** → default
- **Compliance** → powerful (most critical pass — design/plan/rules alignment)

The orchestrator must not:
- report as a defect something already documented as an accepted constraint
- run a broad noisy review without proper scoping
- treat every deviation from plan/design as an error without evaluating context

## Reports

### Task-scoped reports

If a task folder exists in `.ai/tasks/` for the current work, save the report there:
- `.ai/tasks/<task-folder>/review.md`

No need to ask — save automatically.

### Ad hoc reports

When there is no task folder, you are in ad hoc mode.

**STOP — Ad Hoc Save Gate (mandatory)**

In ad hoc mode you MUST NOT write, create, or save any report file until the user explicitly chooses to save. This is a hard gate — no exceptions.

Flow:
1. Generate the report content **in conversation only** (do not call Write/Edit/create file).
2. Present the report to the user inline.
3. Ask the user (use `{{ASK_USER}}` if available) which action to take:
   - **Save report to file** — only then write to `.ai/reports/YYYY-MM-DD-HHMM-<scope>.review.md`
   - **Run /cp-fix now** — pass results through conversation context, no file
4. Wait for the user's explicit choice before any file I/O.

Violating this gate (saving before asking) is a critical workflow error.

### Filename rules

Before generating the filename, get the current time by running a shell command: `date +%H%M` (Unix/macOS) or `Get-Date -Format 'HHmm'` (PowerShell/Windows). Use the real output in the HHMM part. Never hardcode or guess the time.

Save files using the Write tool — it creates parent directories automatically. Do not use shell commands (`mkdir`, `New-Item`) to create directories.

## Report Format

The first line of every report file is reserved for processing metadata (e.g. `<!-- cp-rules: processed YYYY-MM-DD -->`). When creating a new report, leave the first line empty. When editing an existing report, never modify or remove the first line.

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

After presenting the report, offer `/cp-fix` to fix findings. Do not invoke it automatically — the user decides.

## Scope Detection Commands

### Task-scoped (plan/design review)

When the user passes a path to `.ai/tasks/` (plan, design, or task folder):
1. Read the referenced plan and/or design documents
2. Check whether implementation code already exists (look for files mentioned in the plan)
3. If **no implementation yet** — the scope is the documents themselves. Review the plan/design for completeness, consistency, and alignment with project rules. Do NOT run git diff or look for branch changes.
4. If **implementation exists** — use the plan to determine which files to review, then proceed with normal scope detection for those files.

### Default (no args) — committed diff vs main:
```bash
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff --name-only ${MAIN_BRANCH}...HEAD
```

If diff is empty — ask the user for scope (offer: review specific files, review full project, or cancel). Use `{{ASK_USER}}` if available.

Uncommitted changes:
```bash
(git diff --name-only HEAD; git ls-files --others --exclude-standard) | sort -u
```

Entire project — detect primary language(s) from existing files, collect all source files. Exclude: build output, dependencies, generated files, lock files.

Specific paths — use as-is. If a directory — find all source files inside it.

{{FILE_DISCOVERY}}

## Blocker Policy

Stop and ask the user when:
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation fails after 3 attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Report accepted constraints as defects** — if something is documented as an accepted trade-off, it is not a finding
- **Run quality pass before compliance pass** — compliance must come first, always
- **Review 0 files silently** — if scope is empty, stop and ask
- **Guess scope** — when ambiguous, ask with concrete options
- **Save ad hoc reports without user permission** — the ad hoc save gate is a hard requirement
- **Merge or take destructive git actions** — review is read-only unless explicitly requested

## Completion Criteria

This skill is complete when the compliance pass and quality pass are both finished and the report is either presented inline or saved to file.
