---
name: cp-fix
description: Fix issues found during code review
---

# /cp-fix

Process open findings from `/cp-review`.

## Source

Accept either:
- a saved review report path (explicit argument)
- the latest review report from the current workflow task
- the current conversation context if review just finished

### No-argument behavior

When invoked without arguments:
1. Check for an active workflow task — if it has a single report with `open` findings, use it.
2. If multiple reports with `open` findings exist (across `.ai/tasks/` and `.ai/reports/`), list them and ask the user which one to work with. Use `AskUserQuestion` if available.
3. If the current conversation contains review results that were not saved to file, use those.

4. If no reports and no conversation context exist, inform the user: "No review report found. Run `/cp-review` first or provide a report path."

Do not guess which report to use when multiple candidates exist.

## Processing Order

Only process `open` findings. Process them **strictly in report order** — do not reorder by type, severity, or your own judgment. The review already places findings in the correct processing order.

## Progress Tracking (mandatory)

Before starting fixes, you MUST create TodoWrite items **only for `open` findings**, in report order. Skip findings that are already `resolved`, `skipped`, or `deferred`.

**Naming format:** each item MUST start with the finding number and severity from the report:
```
#1 [Critical] file:line — short description
#2 [Important] file:line — short description
#3 [Minor] file:line — short description
```

Mark each as `in_progress` when working on it and `completed` when bounded revalidation confirms the fix.

### Parallelization approval

After creating the full task list, if some findings are independent and can be fixed in parallel:
1. Present the proposed parallel groups to the user.
2. Wait for explicit approval before parallelizing.
3. If not approved, process all findings sequentially in report order.

Sequential processing is the default. Parallel processing requires user confirmation.

## Context Gathering

Before dispatching fix agents, read project rules from ``.claude/rules/*.md` and `CLAUDE.md``. Pass the rules summary as `{PROJECT_RULES}` to each fix agent so it can respect codestyle, testing, and naming conventions.

## Fix Policy

Before starting fixes, determine:

**Severity scope** (applies to quality findings only — compliance findings are always processed regardless of this setting):
- critical only
- critical + important
- all

**Processing style:**
- manual per item
- auto simple, ask-user for complex cases
- custom user-defined policy

If policy is not already clear, ask the user.

### Defer-to-draft intent

When the user responds to a finding with natural language that implies deferral to a draft, recognize these intents and treat them as "defer + create draft" (proceed to Draft Creation flow):
- direct: "отложи в черновик", "создай черновик", "в драфт", "save as draft", "create a draft"
- indirect: "отложи на будущее", "это потом", "слишком большое", "не сейчас", "skip and save for later"
- scope-based: "это отдельная задача", "это надо прорабатывать отдельно", "this needs its own task"

If the user says just "пропусти" / "skip" without mentioning drafts or future work, treat it as a regular skip (`skipped`, no draft). If ambiguous, ask once.

## Execution Rules

- process findings in report order (see Parallelization approval for exceptions)
- update report tracking fields after each fix
- allow alternative fixes when there are real trade-offs: auto-fix when intent is clear, ask the user when multiple valid fixes exist
- run bounded revalidation before closing each finding

### Final Verification Pass

After all fixes, run all relevant project checks:
- lint
- tests
- build or typecheck if applicable
- other mandatory checks from project rules

Bounded revalidation after fixes must confirm that the addressed risks are actually closed before marking each finding resolved.

If fixes lead to conflicting findings, unclear fix policy, or repeated revalidation failure, treat it as a blocker and stop.

## Report Mutation (incremental, mandatory)

**First line preservation:** the first line of a report file is reserved for processing metadata. Never modify, move, or remove it when editing the report.

Update the report file **immediately after each finding** is resolved, skipped, or deferred — not in a batch at the end. This is a hard requirement for resumability: the session may be interrupted at any point, and the next `/cp-fix` run must see which findings are already handled.

For each processed finding, update in the report file:
- **Status:** `open` → `resolved` | `skipped` | `deferred`
- **Resolved via:** what was changed (file:line, commit, or "skipped")
- **Resolution notes:** brief explanation

Order of operations per finding:
1. Apply fix (or decide to skip/defer)
2. Run bounded revalidation
3. **Persist tracking update (mandatory — do this, not skip):**
   - If a report file exists → **edit the report file right now** using the Edit tool. Find this finding's block and replace:
     - `**Status:** open` → `**Status:** resolved` (or `skipped` / `deferred`)
     - `**Resolved via:**` → `**Resolved via:** <what was changed, e.g. file:line or "skipped">`
     - `**Resolution notes:**` → `**Resolution notes:** <brief explanation>`
   - If no file (context-only mode) → record the update in conversation memory
4. Mark the TodoWrite item as completed
5. Move to the next finding

**Not updating the report file after each finding is a workflow violation.** The file is the source of truth for resumability.

### Mid-process save

If the user asks to save the report at any point during the fix process, immediately:
1. Write the report file to `.ai/reports/` with all current tracking state (already resolved + still open findings). Use `mkdir -p` for the directory — do not check existence separately or ask permission.
2. From this point forward, the file exists — all subsequent findings use file-based persistence in step 3 above.

### End of process (context-only mode)

If no report file was created during the process, the ad hoc save gate at the end offers to write the final report.

The report remains the resumable source of truth across `/cp-fix` runs.

### Draft Creation

Drafts are lightweight task sketches stored in `.ai/drafts/`. They capture enough context for `/cp-idea` to start a full task later. Drafts can be created by any skill — fixers defer findings, `/cp-idea` saves side-topics or early-stage ideas.

#### Creating a draft

1. Check `.ai/drafts/` for existing drafts that cover the same scope (same file + same area, or same concept). If a matching draft exists, show it to the user and ask whether to update it or create a new one.
2. Run `date +%Y-%m-%d-%H%M` to get the current timestamp. Never hardcode or guess the time.
3. Create the draft file at `.ai/drafts/<YYYY-MM-DD-HHMM>-<slug>.draft.md`. Use `mkdir -p` for the directory.
4. If created from a fixer — update the report finding: set `**Status:** deferred` and add `**Draft:** .ai/drafts/<YYYY-MM-DD-HHMM>-<slug>.draft.md`.

#### Draft file format

```markdown
# Draft: <title>

**Status:** open
**Created:** <YYYY-MM-DD> by <source-skill>

## Origin

- Source: <source-skill> (<context — e.g. report path, task path, or "ad hoc">)
- Finding: #N [Severity] — short description (if from a fixer)
- Parent task: <task-directory-path> (if created during another task's workflow)

## Problem

<what needs to be done, in which area/module, why it matters — enough context for cp-idea to start>

## Context

<clarification results, research findings, approach ideas — whatever was gathered before deferral>

## Hints

<suggestions for future work — what to consider, dependencies, related areas, possible approaches>
```

Fill only the sections that have content. For fixer drafts, `## Context` may be minimal. For `/cp-idea` drafts, it may include clarification and approach discussion results.

#### Slug rules

The slug should be short and descriptive, derived from the subject. Example: `refactor-auth-middleware`, `extract-video-series-utils`.

#### Duplicate check

Before creating a draft, search `.ai/drafts/` for files with `**Status:** open`. Compare:
- same file or module mentioned in `## Problem`
- same concept or description

If a potential duplicate is found, show it to the user and ask:
- **Update existing draft** — append the new context
- **Create new draft** — the topics are different enough to warrant a separate draft
- **Skip draft creation** — do not create a draft

Do not create duplicate drafts silently.

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
- **stage checkpoint** — when a stage or step within a skill completes, log it with the verification result (e.g. analyze clean, tests pass, specific metrics)
- **verification failure** — when a check (analyze, test, lint) fails before being fixed: what failed, what was fixed, and the re-run result (e.g. "analyze: 1 unused_import → removed → re-run clean")
- **file map** — at skill completion, list files created, modified, and deleted during that skill's run
- **tool error** — when a tool call fails (Edit mismatch, Bash error, etc.): which tool, brief cause, and how it was resolved (retry, alternative approach, manual fix)
- **auto-continuation** — when a skill decides to auto-invoke the next skill instead of asking the user: the reason (e.g. "task small + context fresh → auto-continue to /cp-review")
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
- `14:00` **/cp-execute** stage 1 done — extract utils, analyze clean
- `14:02` **/cp-execute** stage 2 — analyze failed: 1 unused_import
  - fix: removed `import 'app_durations.dart'` → re-run clean
- `14:03` **/cp-execute** stage 2 done — extract handler, analyze clean
- `14:04` **/cp-execute** tool error: Edit failed (old_string not found in video_controls.dart)
  - re-read file, updated match context → retry succeeded
- `14:05` **/cp-execute** stage 3 done — final verify, tests pass, 853→689 lines
- `14:06` **/cp-execute** all 3 stages done, build passes
  - files: created `priority_key_handler.dart`, `series_utils.dart`; modified `video_controls.dart`
- `14:06` **/cp-execute** auto-continue → /cp-review (task small, context fresh)
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
- a critical conflict exists between design, plan, code, rules, or repo state
- intent or choice is ambiguous and affects implementation meaning
- required tools, access, or dependencies are missing
- verification or revalidation repeatedly fails after reasonable attempts

Do not push the workflow forward on guesses. Infer when safe, ask when ambiguous.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `AskUserQuestion` if available on the current platform.

## Completion Criteria

This stage is complete when selected findings are resolved with evidence and final verification is fresh.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.

## Anti-patterns

Do NOT:
- **Batch report updates to the end** — update tracking fields immediately after each finding, not in bulk
- **Reorder findings by type, severity, or your own judgment** — always preserve report order as-is
- **Skip bounded revalidation** — every fix must be verified before being marked resolved
- **Save ad hoc reports without user permission** — the ad hoc save gate is a hard requirement
- **Parallelize without user approval** — sequential processing is the default

## Code Path Complete

### Within a workflow task

After `/cp-fix` and final verification, the code path is complete but the workflow task is not.

Next mandatory step: `/cp-docs`. Offer two paths:
- **continue now** — invoke `/cp-docs` (Use the Skill tool to invoke the target skill directly.)
- **hand off to a new session** — provide `/cp-docs <task-artifact-path>` for the user to run later

When the user chooses to continue, invoke `/cp-docs` immediately. Do not tell the user to run it manually. Manual invocation is only for handing off to a new session.

Do not automatically clean up branches, worktrees, or execution environment.
Cleanup is allowed only as an explicit decision considering the next workflow step.

### Ad hoc fix (no active workflow task)

After all fixes and final verification, the work is complete. No `/cp-docs` handoff is required.

If the source report was a saved file, update its tracking fields as usual.

#### STOP — Ad Hoc Save Gate (mandatory)

If findings were passed through conversation context (no saved file), you MUST NOT write any report file until the user explicitly chooses to save. This is a hard gate — no exceptions.

Flow:
1. Present the completed report with all resolution tracking fields **in conversation only**.
2. Ask the user (use `AskUserQuestion` if available):
   - **Save report to file** — only then write to `.ai/reports/`
   - **Do not save** — findings and resolutions stay in conversation only
3. Wait for the user's explicit choice before any file I/O.

Violating this gate (saving before asking) is a critical workflow error.
