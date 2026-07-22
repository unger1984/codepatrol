# Compliance routing design

## Goal
Reduce token consumption of compliance reviews across Claude, Codex, Cursor, OMP, and OpenCode without weakening deep review where explicit contracts or high-risk changes exist.

## Routing
Each review begins with local, cheap triage. It collects the reviewed scope and extracts only applicable rules, approved design/plan sections, documented constraints, and accepted trade-offs.

Triage sets `requires_deep_compliance` when at least one condition holds:
- an approved design or plan is applicable;
- the scope changes a public API;
- the scope touches authentication, authorization, security, payments, personal data, or a data migration;
- triage finds a potential conflict with an explicit requirement.

When `requires_deep_compliance` is true, dispatch the powerful compliance reviewer before quality regardless of scope size. Scope thresholds govern only quality-reviewer dispatch. When false, the orchestrator completes compliance by checking every extracted rule and constraint against the scope, records those checks and findings in the unified report, and stops before quality with `NEEDS_CHANGES` for any compliance violation. This does not omit the compliance pass; it avoids an unnecessary powerful subagent when no contract requires deep comparison.

## Context contract
When dispatched, the compliance reviewer receives the minimal prepared context: changed files, relevant rule excerpts, relevant design/plan excerpts, and applicable constraints/trade-offs. It must not perform broad discovery for unrelated documents.

## Self-check
Design and plan self-checks retain powerful compliance review because the artifact itself is an explicit contract. The dispatch instructions must prepare and pass only the artifact, applicable rule/document excerpts, and explicit requirements. Artifact integrity and plan completeness retain their existing cheaper reviewers.

Update shared review-dispatch and planning-self-check templates for Claude, Codex, Cursor, OMP, and OpenCode. Update the shared `/cp-review` workflow with triage and the OMP compliance-reviewer contract. Synchronize the affected user-facing README entries and existing AI documentation for the review workflow.

## Verification
Add a non-installing all-platform generation command that writes to isolated temporary output directories. Verify resolved includes, absence of placeholders, and routing conditions in `cp-review` and `using-codepatrol` for each platform. Retain `./install.sh build` plus an empty `skills/` diff for the Claude generated output.
