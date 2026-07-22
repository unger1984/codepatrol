- When `requires_deep_compliance` is true, dispatch `compliance-reviewer` first with only the reviewed
  files and minimal prepared context.
- After compliance is acceptable, use `Task` with these registered agents: `quality-reviewer` for
  architecture/security/testing and `quick-reviewer` for conventions/compatibility.
- Send the needed quality passes in one `tasks[]` batch when parallel execution is allowed.
- The agent definitions select `@task` and `@smol`; do not override their models. These roles resolve
  through the user's `modelRoles` configuration.
- If a required agent is unavailable or disabled, stop with a blocker. Never silently substitute the
  built-in `reviewer` or an unspecified task agent.
