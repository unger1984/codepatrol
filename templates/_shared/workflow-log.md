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
