---
name: cp-review
description: Use to review code changes for compliance and quality before merging
---

# /cp-review

Review implementation with a two-pass review model: compliance first, then quality.

## Progress Tracking (mandatory)

Before dispatching reviewers, you MUST create TodoWrite items for all review passes.
Mark each as `in_progress` when dispatching and `completed` when results are collected.
This provides visual progress to the user.

Create and update TodoWrite items in the same tool batch as the first scope read, review dispatch, or report action when the platform supports batching. Otherwise update them with the nearest real action; never spend a separate turn only on tracking.

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

If you cannot confidently determine scope, OR if the determined scope is empty — stop and ask with concrete options. Use `AskUserQuestion` if available.

Never guess scope. Never review 0 files silently. Wrong scope = wasted review.
Do not run diffs, merge branches, or take any destructive action unless explicitly requested.

## Research Before Review

Before starting review:
- read project rules from ``.claude/rules/*.md` and `CLAUDE.md``
- if `.ai/docs/README.md` exists, read it and only relevant domain/shared docs
- if a task folder exists in `.ai/tasks/` for the current work, read design and plan files
- identify documented exceptions, accepted trade-offs, and constraints
- then read the relevant code

For the compliance pass, mandatory sources are:
- project rules from ``.claude/rules/*.md` and `CLAUDE.md``
- approved design (if exists in `.ai/tasks/`)
- current plan (if exists in `.ai/tasks/`)
- documented constraints and accepted trade-offs

### Prepared Context

Before the compliance pass or any quality dispatch, prepare one cited `prepared_context` package.

`prepared_context` must contain:
- `review_scope`: exact reviewed files, grouped scope manifest, changed public surfaces, and the routing predicates evaluated for this review
- `applicable_rules`: only relevant rule excerpts with source citations
- `applicable_constraints`: only relevant design, plan, and documentation excerpts plus accepted trade-offs, each with source citations
- `missing_context_blockers`: required context that could not be located or cited

Each excerpt must carry a concrete source citation (`path:line` or the platform's equivalent). Reviewers receive only the scope manifest, excerpts, and blockers relevant to their assigned pass. If required context is missing, return a blocker instead of assuming.

Prepare `prepared_context` inline for normal scope. You may dispatch one fast read-only context preparer only when the review scope exceeds 20 files or the applicable context must be assembled from multiple rule, design, or documentation sources. The preparer must return cited excerpts and blockers only; it must not review code, widen scope, or replace compliance or quality judgment.

### Compliance Triage

Before the compliance pass:
1. Collect reviewed files and changed public surfaces.
2. Build the cited `prepared_context` package.
3. Mark `security_sensitive_scope` true when the scope touches authentication, authorization, secrets, payments, personal data, or another explicit security boundary.
4. Mark `architecture_risk` true when any of these predicates apply: cross-package or cross-service boundary, storage or data-model consistency, authentication or authorization boundary, concurrency or background work, public API or SDK compatibility, or a cross-cutting multi-module refactor.
5. Set `requires_deep_compliance` to true if an applicable approved design or plan exists, the scope changes a public API, `security_sensitive_scope` is true, or triage finds a potential conflict with an explicit requirement.
6. Record the evaluated predicates, cited excerpts, and any blockers in the unified report context.

No broad discovery of unrelated documents occurs after triage.

## Review Order

The order is mandatory:
1. compliance pass
2. quality pass

### Compliance Pass

- If `requires_deep_compliance` is true, dispatch the powerful compliance reviewer before quality.
- If false, compare every extracted requirement locally against the reviewed scope, record each checked requirement and finding in the unified report, and stop before quality with `NEEDS_CHANGES` for any compliance violation.

### Quality Pass

Review engineering quality after compliance is acceptable. Preserve all five dimensions and record an explicit verdict for each one:
- architecture and maintainability
- security and reliability risks
- testing and verification adequacy
- conventions and local code quality
- compatibility and deprecated API usage

For every dispatched reviewer, pass only the assigned `prepared_context` excerpts, scope manifest, and blockers. Missing required context is a blocker, not permission to guess.

## Execution Model

- **simple scope** (≤5 reviewable files) — the orchestrator runs compliance directly after triage and may run quality directly when compliance is clean
- **medium scope** (6–20 reviewable files) — the orchestrator may dispatch quality subagents at its discretion after compliance is clean
- **large scope** (>20 reviewable files) — the orchestrator must dispatch quality-oriented reviewer agents after compliance is clean
  - for large low-risk scope (`architecture_risk` false and `security_sensitive_scope` false), use adaptive grouping: one `quality-reviewer` assignment may cover architecture, security/reliability, and testing together, and one `quick-reviewer` assignment may cover conventions and compatibility together
  - if `architecture_risk` is true, dispatch a separate powerful architecture reviewer for the architecture dimension
  - if `security_sensitive_scope` is true, dispatch an independent security review; do not treat deep compliance as a substitute for quality security review
  - grouped reviewers must still return an explicit verdict for every dimension they were assigned
- Use Agent only for the reviewer assignments already decided by the shared routing contract. Pass each reviewer only its assigned `prepared_context` excerpts, scope manifest, and blockers. Use `run_in_background=true` only for independent quality reviewers after compliance is clean, and use the `model` parameter for the configured tier, including a powerful `architecture-reviewer` when common routing requires it.
- all findings from subagents must be normalized into one report

## Subagent Model Policy

Choose the cheapest model that can handle the task. If the platform supports model selection for subagents, use it.

### Model Tiers

| Tier | Description | Use when |
|------|-------------|----------|
| **fast** | Cheapest/fastest available | Simple, well-scoped tasks with clear instructions |
| **default** | Mid-range | Most subagent work requiring comprehension and judgment |
| **powerful** | Most capable available | Complex reasoning, ambiguous constraints, tasks that failed at a lower tier |

### Platform Model Selection

Tiers are logical task categories, not platform model-role names. In particular, `default` does not
refer to a platform's `default` role or imply a fixed capability level. When a platform dispatches a
named agent definition, that definition selects the model or role.

### Ceiling Rule

Respect a capability ceiling only when the platform enforces one. Do not infer a ceiling from model-role
names or override the model selected by a platform agent definition.

### User Override

If project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers (e.g., `fast: haiku`,
`default: sonnet`), use it. User-defined mapping takes priority over automatic selection.

### Escalation on Failure

For failure handling and escalation, see Subagent Limits (included separately in each skill).

### Subagent Limits

Every dispatched subagent is bounded:

- **Max tool calls:** 30 per subagent. The subagent must return its best result within this budget.
- **Partial results:** if a subagent hits the limit before completing, it must return what it has gathered so far — not an empty or error response.

**Failure escalation chain:**

1. Subagent returns incomplete or unusable result → escalate model tier (per Model Tiers policy, max one escalation)
2. Escalated subagent still fails → treat as a blocker
3. Blocker handling: present partial results to the user, explain what the subagent could not complete, and offer options (continue manually, narrow scope, skip this pass)

Do not retry a subagent at the same tier. Do not wait indefinitely for a subagent response.

Starting tier by reviewer role:
- **Conventions / Compatibility** → fast
- **Testing / Security / grouped low-risk quality** → default
- **Architecture** → powerful when `architecture_risk` is true, otherwise default
- **Compliance** → powerful (most critical pass — design/plan/rules alignment)

These are CodePatrol execution tiers, not platform model-role names. Platform adapters map
them to their available subagent and model-selection mechanisms; `default` here never refers
to a platform's `default` model role.

The orchestrator must not:
- report as a defect something already documented as an accepted constraint
- run a broad noisy review without proper scoping
- treat every deviation from plan/design as an error without evaluating context
- skip local compliance when deep routing is false
- send unrelated discovery work to a deep reviewer
- dispatch quality review after an open compliance violation
- invent missing context instead of returning a blocker
- conflate quality security review with deep compliance

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
3. Ask the user (use `AskUserQuestion` if available) which action to take:
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
1. [CATEGORY] `file:line` — concise title
   **Finding type:** compliance | quality
   **Problem:** observed condition and triggering scenario
   **Why it matters:** causal chain to concrete impact
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
- when aggregating subagent results, always preserve the finding explanation, Fix, and code snippets
## Finding Communication

Before drafting findings, determine the language required by project rules. Write the finding's title,
problem, impact, and fix in that language. If rules do not specify a language, use the language of the
user's current conversation; a bare review command inherits the preceding user messages. If conversation
language is unavailable, use the active user-facing language. Keep identifiers, API names, paths, and code
unchanged.

Make every non-trivial finding understandable without reading the reviewed code first:
- describe the observed behavior or code condition;
- explain the triggering scenario and causal chain to the concrete impact;
- state why that impact matters to the user, system, or future maintainer;
- give an actionable fix, including a code snippet where it removes ambiguity.

When more than one reasonable fix exists for a non-trivial finding, list each as `A)` / `B)` and state:
- what changes;
- advantages and disadvantages;
- when to choose it.

Do not invent alternatives for a simple, unambiguous repair, such as adding a clearly missing test. State
the direct fix instead.

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

If diff is empty — ask the user for scope (offer: review specific files, review full project, or cancel). Use `AskUserQuestion` if available.

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
- verification or revalidation fails after 3 attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
When asking the user, use `AskUserQuestion` if available on the current platform.

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
