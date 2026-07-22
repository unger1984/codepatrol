- When `requires_deep_compliance` is true, dispatch the powerful compliance reviewer first with only the
  reviewed files and minimal prepared context.
- After compliance is acceptable, enable multi-agent tools (`spawn_agent`, `wait`, `close_agent`) and
  launch only the needed quality reviewers in parallel.
- Use the configured model tier for each reviewer role. Use `send_input` for follow-ups if needed.
