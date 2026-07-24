# Handoff and Flexible Fix Policy

## Goal

Record material implementation-time deviations from an approved plan and let users express a mixed fix policy in
natural language without ambiguous or tool-dependent prompts.

## Handoff

Create `.ai/tasks/<task>/handoff.md` only on the first consequential, non-material deviation. It is append-only.
Each entry records the affected plan step, evidence, chosen adaptation, rationale, impact, authority, verification,
and review focus. It is not a second plan or authority to change approved design, public API, security, migrations,
architecture, scope, or acceptance criteria; those changes require user approval and a revised design or plan.

`/cp-review` reads `handoff.md` when present and evaluates the implementation against design, plan, and handoff
entries. It cites an entry instead of treating an authorized adaptation as an automatic compliance defect.

## Flexible Fix Policy

When no interactive question tool exists, ask one human-readable question at a time. Numbered options are examples,
not a required input format. The user may answer with a number, free text, or a mixed policy such as “1, 2, and 5
one by one with explanations; handle the rest in parallel where safe.”

The agent restates its parsed policy and waits for confirmation before the first mutation. Any ambiguous part requires
one focused clarification. Manual findings pause for a decision; automatic findings remain subject to existing safety
and parallel-approval gates.
