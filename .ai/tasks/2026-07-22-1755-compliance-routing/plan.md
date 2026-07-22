# Compliance Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans task-by-task.

**Goal:** Add local compliance triage and use powerful review only for explicit contracts or high-risk scopes across all five platforms.

**Architecture:** Shared `/cp-review` text owns routing semantics. Platform partials own only dispatch syntax. `install.sh validate` generates all platforms into a temporary directory and checks resolved output.

**Global Constraints**
- Edit templates/platforms for behavior; never hand-edit `skills/`.
- Regenerate `skills/` only via `./install.sh build`.
- `requires_deep_compliance` is true for applicable design/plan, public API, high-risk domain, or explicit-contract conflict.
- False triage compares extracted requirements locally and blocks quality with `NEEDS_CHANGES` on violations.
- Powerful planning self-checks receive only minimal prepared context.
- Validation must neither install skills nor mutate `skills/`.

### Task 1: Add all-platform validator and review routing

**Files:** `install.sh`, `.github/workflows/ci.yml`, `templates/cp-review/SKILL.md`, `templates/_shared/reviewer-dispatch-*.md`, `platforms/omp-agents/compliance-reviewer.md`.

- [ ] Add `./install.sh validate`. In a subshell, generate exactly `claude codex cursor omp opencode` into `mktemp -d`; clean it with an `EXIT` trap. Assert generated Markdown has no unresolved include directives or `{{UPPER_SNAKE_CASE}}` placeholders.
- [ ] After routing is implemented, assert generated `cp-review/SKILL.md` contains `requires_deep_compliance`, `minimal prepared context`, `compare every extracted requirement locally`, and `stop before quality with \`NEEDS_CHANGES\``; assert generated `using-codepatrol/SKILL.md` contains `minimal prepared context`.
- [ ] Add CI step `./install.sh validate` before the Claude build.
- [ ] Add compliance triage in `templates/cp-review/SKILL.md`: collect scope and only applicable excerpts; record evaluated predicates; deep-dispatch only for the four predicates; otherwise locally compare every extracted requirement, record checks/findings, and block quality on violations. File-count thresholds govern quality only.
- [ ] Keep common routing semantics in `cp-review`; platform dispatch partials retain adapter mechanics only. Preserve OMP registered-agent constraints.
- [ ] Require the OMP compliance reviewer to use supplied reviewed files and minimal prepared context only; missing required context is a blocker.
- [ ] Verify: first run `./install.sh validate` before implementation and observe missing-command failure; after implementation run it successfully.

### Task 2: Scope planning compliance self-checks

**Files:** `templates/_shared/planning-self-check-{claude,codex,cursor,omp,opencode}.md`.

- [ ] For every powerful compliance self-check, require only minimal prepared context: current artifact, applicable rule/document excerpts, and explicit requirements. Forbid unrelated broad discovery.
- [ ] Retain agent selection and powerful compliance tier for designs and plans, especially OMP `Task` roles.
- [ ] Verify: `./install.sh validate` succeeds for every platform.

### Task 3: Synchronize documentation and generated Claude output

**Files:** `README.md`, `README.ru.md`, `.ai/docs/shared/architecture.md`, `.ai/docs/domains/review-system.md`, `.ai/docs/domains/skills/cp-review.md`, `.ai/docs/domains/skills/using-codepatrol.md`, `.ai/docs/domains/skills-reference.md`, `skills/`.

- [ ] Document local triage, all four deep predicates, quality gating, minimal prepared context, and the non-installing `./install.sh validate` command in both READMEs and affected AI docs.
- [ ] Run `./install.sh build`; do not manually modify generated files.
- [ ] Verify: `./install.sh validate && git diff --quiet skills/`; confirm required `skills/using-codepatrol/SKILL.md`, `skills/cp-review/SKILL.md`, `skills/cp-review/architecture-reviewer.md`, and `skills/cp-review/codestyle-reviewer.md` exist.

## Final Verification

- [ ] Run `./install.sh validate`.
- [ ] Run `./install.sh build && git diff --quiet skills/`.
- [ ] Confirm documentation covers the routing and validation contracts.
