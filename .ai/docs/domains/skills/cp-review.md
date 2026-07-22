# cp-review

## Purpose

Two-pass code review: mandatory local compliance triage first, then quality after clean compliance.

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

Triage collects reviewed files and changed public surfaces, then extracts only applicable rule excerpts, approved design/plan excerpts, documented constraints, and accepted trade-offs. It records the predicates and extracted contract in report context without broad unrelated discovery.

`requires_deep_compliance` is true for an applicable approved design or plan, public API change, high-risk domain change (authentication, authorization, security, payments, personal data, or data migration), or a potential explicit-contract conflict. The powerful compliance reviewer receives only the minimal prepared context: reviewed files and applicable excerpts.

Otherwise the orchestrator compares every extracted requirement locally, records each check and finding, and stops before quality with `NEEDS_CHANGES` for any violation.

### Pass 2 — Quality

Five dimensions, each with optional specialized reviewer:

| Dimension | Reviewer file | Starting tier |
|-----------|--------------|---------------|
| Architecture | `architecture-reviewer.md` | default |
| Security | `security-reviewer.md` | default |
| Testing | `testing-reviewer.md` | default |
| Conventions | `codestyle-reviewer.md` | fast |
| Compatibility | `compatibility-reviewer.md` | fast |

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
| Compliance reviewer | powerful | Design/plan/rules alignment |
| Architecture reviewer | default | Architecture quality |
| Security reviewer | default | Security risks |
| Testing reviewer | default | Test coverage and quality |
| Codestyle reviewer | fast | Conventions and style |
| Compatibility reviewer | fast | Deprecated APIs |

## Change Impact

- Adding a new reviewer dimension: create template in `cp-review/`, update dispatch logic
- Changing report format: impacts cp-fix parsing and cp-rules analysis
