# cp-review

## Purpose

Two-pass code review: build cited `prepared_context`, run compliance first, then quality after clean compliance.

## When to read

- Running code review
- Understanding the two-pass model
- Configuring specialized reviewer subagents
- Working with report format and severity levels

## Related docs

- [cp-fix](cp-fix.md) — next step when findings exist
- [Review System](../review-system.md) — detailed review mechanics

---

## Role

**Multi-dimensional reviewer.** Runs compliance and quality passes, dispatches specialized reviewer subagents, produces a unified report.

## Scope Modes

- Current working tree / staged changes
- Committed branch diff / branch vs branch
- PR/MR diff
- Entire project
- Explicit file/directory paths
- Task-scoped (design + plan from `.ai/tasks/`)

Default (no args): committed diff vs main.

## Two-Pass Review Model

### Compliance Triage

Triage builds one cited `prepared_context` package with the exact reviewed files, grouped scope manifest, changed public surfaces, evaluated routing predicates, only applicable rule excerpts, only applicable design/plan/documentation/accepted-trade-off excerpts, and missing-context blockers.

`requires_deep_compliance` is true for an applicable approved design or plan, a public API change, a security-sensitive boundary, or a potential explicit-contract conflict. `architecture_risk` is true for cross-package or cross-service boundaries, storage or data-model consistency, auth/authz boundaries, concurrency or background work, public API or SDK compatibility, or cross-cutting multi-module refactors.

For normal scope the orchestrator prepares this package inline. One fast read-only context preparer is allowed only for review scope above 20 files or when relevant rules, design, and docs come from multiple sources. Missing required context blocks the review instead of widening discovery or guessing.

If deep routing is required, the powerful compliance reviewer receives only the relevant `prepared_context` excerpts, scope manifest, and blockers. Otherwise the orchestrator compares extracted requirements locally and stops before quality with `NEEDS_CHANGES` on any violation.

### Pass 2 — Quality

Five dimensions remain mandatory: architecture, security/reliability, testing/verification, conventions, and compatibility.

For large low-risk scope, routing becomes adaptive: one grouped `quality-reviewer` may cover architecture, security/reliability, and testing, and one grouped `quick-reviewer` may cover conventions and compatibility. Each grouped reviewer must still return an explicit verdict for every assigned dimension.

If `architecture_risk` is true, route architecture to a separate powerful architecture reviewer. If the scope is security-sensitive, keep an independent security quality review; deep compliance never replaces it.

## Report Storage

| Context | Path | Condition |
|---------|------|-----------|
| Task folder exists | `.ai/tasks/<task>/review.md` | Automatic |
| Ad hoc | `.ai/reports/YYYY-MM-DD-HHMM-<scope>.review.md` | Only after Save Gate |

## Ad Hoc Save Gate

When no task folder exists:
1. Report generated **in conversation only**
2. Cannot write to file until user explicitly chooses
3. Offer: "Save to file" or "Run /cp-fix now"

## Handoff

After presenting the report, offer `/cp-fix`. Do not invoke automatically — user decides.

## Subagents

| Role | Tier | Purpose |
|------|------|---------|
| Compliance reviewer | powerful | Design/plan/rules alignment when deep routing is required |
| Architecture reviewer | default or powerful | Architecture quality; powerful when `architecture_risk` is true |
| Security reviewer | default | Security and reliability risks |
| Testing reviewer | default | Test coverage and verification quality |
| Codestyle reviewer | fast | Conventions and style |
| Compatibility reviewer | fast | Deprecated APIs and compatibility |

## Change Impact

- Adding a new reviewer dimension: create template in `cp-review/`, update dispatch logic
- Changing report format: impacts cp-fix parsing and cp-rules analysis
