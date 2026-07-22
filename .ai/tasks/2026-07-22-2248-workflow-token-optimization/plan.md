# Workflow Token Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce repeated review and fix workflow context while preserving compliance, quality gates, and explicit user control.

**Architecture:** Keep routing semantics in shared skill templates and platform differences in partials. `/cp-review` prepares a cited context package before quality dispatch; `/cp-fix` makes user approval explicit before manual or consequential changes. Documentation describes the resulting contracts; generated Claude skills remain derived output.

**Tech Stack:** Markdown templates, POSIX shell generator, platform `.env` files, generated Claude skills.

## Global Constraints

- Edit `templates/` and `platforms/` only; never hand-edit `skills/`.
- Regenerate `skills/` only with `./install.sh build`.
- Keep deep compliance before quality and preserve all five quality dimensions.
- Do not add a YAML-frontmatter preprocessor; OMP output schemas remain duplicated.
- `manual per item` must not dispatch a fixer, edit files, run a fix command, or mutate report status before the user explicitly selects a fix for that finding.
- User-facing fix choices must use plain language and state benefits, drawbacks, risks, affected files, and verification.
- `auto safe fixes` may apply only an isolated simple repair with one safe option, no observable behavior/public API/schema/config change, and trivial rollback.

---

### Task 1: Add prepared-context and adaptive quality routing contracts

**Files:**
- Modify: `templates/cp-review/SKILL.md`
- Modify: `templates/_shared/reviewer-dispatch-{claude,codex,cursor,omp,opencode}.md`
- Modify: `templates/cp-review/{architecture,security,testing,codestyle,compatibility}-reviewer.md`
- Modify: `platforms/omp-agents/quality-reviewer.md`
- Modify: `platforms/omp-agents/quick-reviewer.md`
- Modify: `platforms/omp-agents/compliance-reviewer.md`

- [ ] Define one cited `prepared_context` package: review scope, changed public surfaces, applicable rule excerpts, applicable design/plan constraints, accepted trade-offs, and missing-context blockers.
- [ ] Require inline preparation for normal scope and permit one fast read-only context-preparer only for review scope above 20 files or multiple design/rule/doc sources.
- [ ] Require every reviewer to receive only relevant excerpts, scope manifest, and constraints; require missing-context blockers rather than assumptions.
- [ ] For large low-risk scope, dispatch `quality-reviewer` for architecture/testing/reliability and `quick-reviewer` for conventions/compatibility. Require an explicit verdict for every assigned dimension.
- [ ] Define architecture-risk predicates: cross-package/service boundary, storage/data-model consistency, auth/authz boundary, concurrency/background work, public API/SDK compatibility, or cross-cutting multi-module refactor. Dispatch a separate powerful architecture reviewer when any applies.
- [ ] Preserve independent security review when the scope is security-sensitive; do not conflate quality security with deep compliance.
- [ ] Preserve all five quality dimensions, compliance-first routing, and platform-specific dispatch mechanics.

### Task 2: Narrow planning self-check context

**Files:**
- Modify: `templates/_shared/planning-self-check-{claude,codex,cursor,omp,opencode}.md`
- Modify: `templates/using-codepatrol/SKILL.md`

- [ ] Define a shared planning prepared-context package with artifact path/type, explicit requirements, cited applicable rule/doc excerpts, applicable approved-design excerpts for plans, and missing-context blockers.
- [ ] Require artifact integrity to receive only artifact structure/link inputs; plan and compliance checks receive their relevant cited subsets.
- [ ] Keep independent artifact, completeness, and compliance checks and their existing tiers.
- [ ] For broad planning context, permit one fast read-only preparer; do not merge independent checks.

### Task 3: Make cp-fix choice policy explicit

**Files:**
- Modify: `templates/cp-fix/SKILL.md`
- Modify: `templates/cp-fix/fix-agent-prompt.md`
- Modify: `templates/_shared/fixer-dispatch-{claude,codex,cursor,omp,opencode}.md`

- [ ] Replace `auto simple, ask-user for complex cases` with `auto safe fixes, ask before consequential or ambiguous fixes`.
- [ ] Add a `Fix Decision Brief` contract: plain-language problem and trigger, recommended fix, materially different alternatives, each option’s changes, benefits, drawbacks/risks, affected files, and verification.
- [ ] Add a Manual Per Item Gate that blocks every fixer dispatch, edit, fix command, and report mutation until the user chooses an option, skips, or stops for the current finding.
- [ ] For automatic fixes, permit only the globally defined safe-simple condition; use a concise brief. Require a full brief and explicit user choice for standard, complex, ambiguous, security/auth/payments/PII/migration/public-API/dependency-upgrade/data-deletion/performance-availability findings, or unclear root cause/verification.
- [ ] Replace full `{PROJECT_RULES}` payload with cited applicable rules and require fixer output to list applied rule citations.
- [ ] Preserve report order, one finding per fixer, bounded revalidation, and incremental report mutation after a selected fix is verified.

### Task 4: Add research source maps and progress batching

**Files:**
- Modify: `templates/_shared/researcher.md`
- Modify: `templates/cp-docs/SKILL.md`
- Modify: `templates/_cp-rules/SKILL.md`
- Modify: `templates/cp-review/SKILL.md`
- Modify: `templates/cp-fix/SKILL.md`

- [ ] Require broad research output to include only draft-relevant claims with `path:line`, exact supporting excerpt, and relevance.
- [ ] Require orchestrators to re-read only changed sources, disputed claims, and final validation sources; narrow research remains inline.
- [ ] Require progress-tool changes to be batched with the first real read/dispatch/edit/verification action when platform tooling supports batching; otherwise update at the nearest real action. Do not skip progress tracking.

### Task 5: Compress duplicate workflow prose and synchronize documentation

**Files:**
- Modify: `templates/{using-codepatrol,cp-review,cp-fix,cp-docs,_cp-rules}/SKILL.md`
- Modify: `README.md`
- Modify: `README.ru.md`
- Modify: `.ai/docs/shared/architecture.md`
- Modify: `.ai/docs/domains/review-system.md`
- Modify: `.ai/docs/domains/skills/{cp-review,cp-fix,using-codepatrol}.md`
- Modify: `.ai/docs/domains/skills-reference.md`

- [ ] Remove only exact/same-meaning duplicated workflow prose within a loaded skill; retain every hard gate, MUST/NEVER, platform contract, and completion condition at least once in that skill.
- [ ] Document adaptive quality routing, cited prepared contexts, planning self-check context, manual-fix gate, safe-auto predicate, source maps, and progress batching.
- [ ] Document the deliberate non-change: no YAML frontmatter include/preprocessor for OMP agent output schema.

### Task 6: Generate and validate

**Files:**
- Modify via generation: `skills/`
- Verify: `install.sh`

- [ ] Run `./install.sh build` to regenerate Claude output.
- [ ] Run `./install.sh validate` for all platform outputs.
- [ ] Assert generated `skills/cp-review/SKILL.md` contains `prepared_context`, `architecture-risk`, and all quality dimensions.
- [ ] Assert generated `skills/cp-fix/SKILL.md` contains `Manual Per Item Gate`, `Fix Decision Brief`, and `auto safe fixes`.
- [ ] Run `git diff --check`, `bash -n install.sh`, and `./install.sh build && git diff --quiet skills/`.

## Final Verification

- [ ] Review every accepted requirement above against templates and generated Claude skills.
- [ ] Run `./install.sh validate` and `./install.sh build && git diff --quiet skills/`.
- [ ] Run a code review and resolve Critical/Important findings before completion.
