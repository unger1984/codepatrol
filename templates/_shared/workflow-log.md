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