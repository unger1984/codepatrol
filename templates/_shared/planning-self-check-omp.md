- Dispatch read-only checks with `Task`: `artifact-reviewer` for artifact integrity; `compliance-reviewer` for design compliance; and, for a plan, `plan-reviewer` for completeness, dependency order, scope, and verification plus `compliance-reviewer` for rules/docs/design compliance. Send independent checks in one `tasks[]` batch.
- These definitions select `@smol`, `@task`, and `@slow`; do not override their models. The roles resolve through the user's `modelRoles` configuration.
- Prefer inline repairs when they are mechanical and obviously local. If fixer agents are needed, dispatch at
  most one fixer wave, grouping related findings by dimension instead of sending a per-finding cascade. After
  applying fixes, run at most one targeted recheck for the touched sections or review dimensions. If unresolved
  findings remain, stop and present them instead of looping. Do not silently apply a fix that changes a
  material design choice or an approved design decision.
- If a selected agent is unavailable or disabled, stop with a blocker. Never silently substitute an unspecified
  task agent.
- Pass the prepared planning context: artifact path/type, explicit requirements, cited applicable
  rule/documentation excerpts, approved-design excerpts for plans, and missing-context blockers. Give
  `artifact-reviewer` only structure/link/placeholder inputs; give `plan-reviewer` and
  `compliance-reviewer` only their relevant cited subsets. Missing context blocks the check; no check performs
  broad discovery.
