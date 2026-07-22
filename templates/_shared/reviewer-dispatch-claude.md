- When `requires_deep_compliance` is true, dispatch the powerful compliance reviewer first with only the
  reviewed files and minimal prepared context.
- After compliance is acceptable, launch only the needed quality reviewers in parallel using Agent tool
  with `run_in_background=true`. Send all Agent calls in a single message for true parallelism.
- Use the `model` parameter to select the configured tier for each subagent.
