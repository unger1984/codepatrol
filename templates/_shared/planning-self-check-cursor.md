- Dispatch planning checks as separate read-only agents. For a design: artifact integrity → fast; rules, docs, and requirement compliance → powerful. For a plan: artifact integrity → fast; completeness, dependencies, scope, and verification → default; rules/docs/design compliance → powerful.
- Pass the prepared planning context: artifact path/type, explicit requirements, cited applicable rule/documentation excerpts, approved-design excerpts for plans, and missing-context blockers. Give artifact integrity only structure/link/placeholder inputs; give plan and compliance checks only their relevant cited subsets. Missing context blocks the check; no check performs broad discovery.
- Prefer inline repairs when they are mechanical and obviously local. If fixer agents are needed, dispatch at
  most one fixer wave, grouping related findings by dimension instead of sending a per-finding cascade. After
  applying fixes, run at most one targeted recheck for the touched sections or review dimensions. If unresolved
  findings remain, stop and present them instead of looping. Do not silently change material design decisions.
