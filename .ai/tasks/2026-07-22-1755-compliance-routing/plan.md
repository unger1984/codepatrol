# Compliance Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce powerful-model compliance reviews while preserving deep compliance checks for explicit contracts and high-risk changes across Claude, Codex, Cursor, OMP, and OpenCode.

**Architecture:** `/cp-review` gains deterministic local compliance triage before quality review. Triage extracts only review-scope facts and applicable contracts, then either performs local compliance comparison or dispatches the platform's powerful compliance reviewer with that prepared context. Planning self-checks remain deep because their artifact is itself an explicit contract. `install.sh validate` generates every platform into isolated temporary directories and validates the generated routing contract without installing anything.

**Tech Stack:** Bash, Markdown templates, platform `.env` substitution, generated Markdown skills, GitHub Actions.

## Global Constraints

- Edit behavior text in `templates/` and `platforms/`; edit the listed script, CI, and documentation files only as specified.
- Never hand-edit `skills/`; regenerate it only with `./install.sh build`.
- Put cross-platform routing semantics in common skill templates; platform partials contain adapter-specific invocation details only.
- Compliance triage is mandatory and precedes quality review.
- `requires_deep_compliance` is true for an applicable approved design/plan, public API change, high-risk domain change, or explicit-contract conflict.
- A false triage result performs local compliance comparison; any violation yields `NEEDS_CHANGES` before quality review.
- Planning self-check compliance always uses the powerful reviewer with minimal prepared context.
- `./install.sh validate` must not install skills or mutate `skills/`.
- Regenerate `skills/` with `./install.sh build`; generated Claude output must match committed `skills/`.

---

## File Structure

- Modify: `install.sh` — expose a non-installing all-platform validator and generated-skill assertions.
- Modify: `templates/cp-review/SKILL.md` — define local triage, deep-routing predicates, local compliance completion, and quality gating.
- Modify: `templates/_shared/reviewer-dispatch-{claude,codex,cursor,omp,opencode}.md` — retain only adapter-specific reviewer invocation details after common triage.
- Modify: `templates/_shared/planning-self-check-{claude,codex,cursor,omp,opencode}.md` — retain platform tooling and add minimal prepared-context instructions for powerful artifact compliance checks.
- Modify: `platforms/omp-agents/compliance-reviewer.md` — constrain the OMP reviewer to supplied scope and minimal prepared context.
- Modify: `README.md` and `README.ru.md` — describe triaged compliance review and the validation command.
- Modify: `.ai/docs/shared/architecture.md` — document the `validate` build-pipeline command.
- Modify: `.ai/docs/domains/review-system.md` — document routing predicates and local/deep compliance outcomes.
- Modify: `.ai/docs/domains/skills/cp-review.md` — document `/cp-review` triage and dispatch contract.
- Modify: `.ai/docs/domains/skills/using-codepatrol.md` and `.ai/docs/domains/skills-reference.md` — document minimal-context powerful planning compliance checks.
- Regenerate: `skills/` — Claude-platform generated output only, via `./install.sh build`.
- Modify: `.github/workflows/ci.yml` — run generated all-platform validation before the existing Claude build/diff check.

### Task 1: Add non-installing all-platform validation

**Files:**
- Modify: `install.sh:29-185,187-272`
- Modify: `.github/workflows/ci.yml:15-24`

**Interfaces:**
- Consumes: `templates/`, `platforms/{claude,codex,cursor,omp,opencode}.env`, existing `generate(platform, output_dir)`.
- Produces: `./install.sh validate`, which returns zero only when all five isolated generated skill trees contain resolved includes/placeholders and required routing text.

- [ ] **Step 1: Add the failing CI invocation before implementation**

Add this step immediately before `Rebuild skills from templates` in `.github/workflows/ci.yml`:

```yaml
      - name: Validate all generated platform skills
        run: ./install.sh validate
```

- [ ] **Step 2: Run the command to prove it is unavailable**

Run: `./install.sh validate`

Expected: non-zero exit and usage output because `validate` is not yet a supported command.

- [ ] **Step 3: Add validation helpers to `install.sh`**

Add `validate_generated_skills()` after `generate()`. It must accept an output directory and platform name, then fail with an explicit error when any generated Markdown file contains `{{@include:`, `{{@platform-include:`, or an unresolved `{{UPPER_SNAKE_CASE}}` placeholder. It must also assert that both generated files contain the routing contract:

```bash
test -f "$output_dir/cp-review/SKILL.md"
test -f "$output_dir/using-codepatrol/SKILL.md"
grep -Fq 'requires_deep_compliance' "$output_dir/cp-review/SKILL.md"
grep -Fq 'minimal prepared context' "$output_dir/cp-review/SKILL.md"
grep -Fq 'compare every extracted requirement locally' "$output_dir/cp-review/SKILL.md"
grep -Fq 'stop before quality with `NEEDS_CHANGES`' "$output_dir/cp-review/SKILL.md"
grep -Fq 'minimal prepared context' "$output_dir/using-codepatrol/SKILL.md"
```

Add `validate)` to the command dispatcher. Run validation in a subshell so its `EXIT` trap cleans temporary output without replacing the existing remote-clone cleanup trap in the parent process. It must loop exactly over `claude codex cursor omp opencode`:

```bash
validate)
    (
        tmp_dir=$(mktemp -d)
        trap 'rm -rf "$tmp_dir"' EXIT
        for platform in claude codex cursor omp opencode; do
            output_dir="$tmp_dir/$platform"
            generate "$platform" "$output_dir"
            validate_generated_skills "$output_dir" "$platform"
        done
    )
    ;;
```

Add this usage line:

```text
  validate Generate every platform in temporary directories and validate generated routing
```

Do not call `clean_installed_skills`, copy to user directories, or change `SKILLS_DIR` in this branch.

- [ ] **Step 4: Run generated-platform validation**

Run: `./install.sh validate`

Expected: zero exit after every platform is generated under a temporary directory; no `skills/` or user installation directory is modified.

- [ ] **Step 5: Commit the independently verifiable validator**

```bash
git add install.sh .github/workflows/ci.yml
git commit -m "feat: validate generated skills for every platform"
```

### Task 2: Route `/cp-review` through deterministic compliance triage

**Files:**
- Modify: `templates/cp-review/SKILL.md:59-128,250-262`
- Modify: `templates/_shared/reviewer-dispatch-claude.md`
- Modify: `templates/_shared/reviewer-dispatch-codex.md`
- Modify: `templates/_shared/reviewer-dispatch-cursor.md`
- Modify: `templates/_shared/reviewer-dispatch-omp.md`
- Modify: `templates/_shared/reviewer-dispatch-opencode.md`
- Modify: `platforms/omp-agents/compliance-reviewer.md:34-38`

**Interfaces:**
- Consumes: reviewed file scope, applicable rule excerpts, applicable design/plan excerpts, documented constraints/trade-offs.
- Produces: `requires_deep_compliance: true | false`; when true, a prepared powerful compliance-reviewer input; when false, recorded local contract checks and either a clean pass or `NEEDS_CHANGES`.

- [ ] **Step 1: Add the local compliance-triage contract to `templates/cp-review/SKILL.md`**

Insert a `### Compliance Triage` section between `Research Before Review` and `Review Order`. Require the orchestrator to:

```markdown
1. Collect reviewed files and changed public surfaces.
2. Extract only applicable rule excerpts, design/plan excerpts, documented constraints, and accepted trade-offs.
3. Set `requires_deep_compliance` to true if an applicable approved design/plan exists, the scope changes a public API, the scope touches authentication, authorization, security, payments, personal data, or a data migration, or triage finds a potential conflict with an explicit requirement.
4. Record the predicates evaluated and the extracted contract in the unified report context.
```

State that no broad discovery of unrelated documents occurs after triage.

- [ ] **Step 2: Replace the compliance-pass and execution-model instructions**

Update `### Compliance Pass` so it has exactly two paths:

```markdown
- If `requires_deep_compliance` is true, dispatch the powerful compliance reviewer before quality and provide only the minimal prepared context: reviewed files, applicable rule excerpts, applicable design/plan excerpts, and documented constraints/trade-offs.
- If false, compare every extracted requirement locally against the reviewed scope, record each checked requirement and finding in the unified report, and stop before quality with `NEEDS_CHANGES` for any compliance violation.
```

Update scope rules so file-count thresholds apply only to quality reviewers. Large scope must dispatch quality dimensions, but must not force powerful compliance when triage is false. Preserve compliance-before-quality in all cases.

Add anti-patterns forbidding: skipping local compliance when deep routing is false; sending unrelated discovery work to a deep reviewer; and dispatching quality after an open compliance violation.

- [ ] **Step 3: Restrict platform reviewer-dispatch partials to adapter mechanics**

Keep cross-platform routing semantics only in `templates/cp-review/SKILL.md`. In each platform partial, retain its existing platform tool syntax for dispatching reviewers after the common triage decision. Do not repeat predicates, quality gating, or prepared-context semantics. For OMP, retain the required `Task` roles, model-role policy, and prohibition on generic-reviewer substitution.

- [ ] **Step 4: Narrow the OMP compliance reviewer contract**

Replace the opening operational instructions in `platforms/omp-agents/compliance-reviewer.md` with a contract requiring provided reviewed files and minimal prepared context as its complete input. It must reject missing required context as a blocker rather than globbing for unrelated designs, plans, or documentation. Preserve its read-only, actionable-finding, and `yield` requirements.

- [ ] **Step 5: Generate and inspect the routing contract on every platform**

Run: `./install.sh validate`

Expected: zero exit. For each generated platform, `cp-review/SKILL.md` contains `requires_deep_compliance`, local-compliance completion, and prepared-context dispatch instructions; `using-codepatrol/SKILL.md` remains generated without unresolved directives.

- [ ] **Step 6: Commit the routing behavior**

```bash
git add templates/cp-review/SKILL.md templates/_shared/reviewer-dispatch-*.md \
  platforms/omp-agents/compliance-reviewer.md
git commit -m "feat: triage deep compliance review routing"
```

### Task 3: Preserve deep planning self-checks with scoped context

**Files:**
- Modify: `templates/_shared/planning-self-check-claude.md`
- Modify: `templates/_shared/planning-self-check-codex.md`
- Modify: `templates/_shared/planning-self-check-cursor.md`
- Modify: `templates/_shared/planning-self-check-omp.md`
- Modify: `templates/_shared/planning-self-check-opencode.md`

**Interfaces:**
- Consumes: current design or plan artifact, applicable rules/docs excerpts, and explicit requirements.
- Produces: a powerful compliance self-check that does not perform broad discovery.

- [ ] **Step 1: Amend each planning-self-check platform partial**

Add this mandatory sentence to each platform variant while retaining its existing agent/tooling language:

```markdown
For every powerful compliance self-check, pass only the minimal prepared context: current artifact,
applicable rule and documentation excerpts, and explicit requirements. It must not perform broad discovery
for unrelated documents.
```

For `planning-self-check-omp.md`, preserve the required `Task` agents and append the sentence after the registered-agent availability rule. Do not lower the compliance reviewer tier for either designs or plans.

- [ ] **Step 2: Generate all platforms and assert the shared planning contract**

Run: `./install.sh validate`

Expected: zero exit; every generated `using-codepatrol/SKILL.md` contains `minimal prepared context` and the mandatory powerful compliance self-check remains present.

- [ ] **Step 3: Commit scoped planning self-checks**

```bash
git add templates/_shared/planning-self-check-*.md
git commit -m "refactor: scope planning compliance checks"
```

### Task 4: Synchronize generated output and user-facing documentation

**Files:**
- Modify: `README.md` and `README.ru.md:44-58,269-300`
- Modify: `.ai/docs/shared/architecture.md:101-119,131-143`
- Modify: `.ai/docs/domains/review-system.md:24-64,184-188`
- Modify: `.ai/docs/domains/skills/cp-review.md:36-55,75-89`
- Modify: `.ai/docs/domains/skills/using-codepatrol.md:55-67,80-83`
- Modify: `.ai/docs/domains/skills-reference.md:74-89`
- Regenerate: `skills/`

**Interfaces:**
- Consumes: final template behavior from Tasks 1–3.
- Produces: documentation that describes triage correctly and generated Claude skills matching their templates.

- [ ] **Step 1: Update both README behavior descriptions and development commands**

In `README.md` and `README.ru.md`, replace the review description with language stating that `/cp-review` performs mandatory local compliance triage and dispatches powerful compliance only when one of these predicates holds: an applicable approved design/plan exists, the scope changes a public API, the scope touches a high-risk domain, or triage finds an explicit-contract conflict. State that it runs quality review only after compliance is clean. Add:

```bash
./install.sh validate # Generate every platform in temporary directories and validate generated skill contracts
```

under the Unix/macOS build commands in each README. Do not claim the command installs anything.

- [ ] **Step 2: Update AI documentation by responsibility**

Make these precise changes:

- `architecture.md`: add `./install.sh validate` to the command table and explain that it uses isolated temporary output for all five platforms without mutating `skills/` or installation directories.
- `review-system.md`: replace the unconditional powerful compliance claim with the four triage predicates, the local-comparison path, the deep minimal-prepared-context path, and the rule that quality starts only after clean compliance.
- `skills/cp-review.md`: add a `Compliance Triage` subsection naming the four predicates and the minimal-prepared-context contract.
- `skills/using-codepatrol.md` and `skills-reference.md`: state that planning compliance self-checks remain powerful but receive only the minimal prepared context: current artifact, applicable excerpts, and explicit requirements.

Keep documentation links and Markdown headings valid; do not change unrelated workflow behavior.

- [ ] **Step 3: Regenerate Claude skills from templates**

Run: `./install.sh build`

Expected: zero exit and regenerated `skills/` reflecting Tasks 2–3. Do not manually edit generated files.

- [ ] **Step 4: Run complete generated-skill verification**

Run:

```bash
./install.sh validate &&
git diff --quiet skills/ &&
test -f skills/using-codepatrol/SKILL.md &&
test -f skills/cp-review/SKILL.md &&
test -f skills/cp-review/architecture-reviewer.md &&
test -f skills/cp-review/codestyle-reviewer.md
```

Expected: zero exit. The first command validates all five platforms in temporary directories; the remaining checks prove committed Claude generated files are current and required files exist.

- [ ] **Step 5: Commit generated output and documentation**

```bash
git add README.md README.ru.md .ai/docs/shared/architecture.md .ai/docs/domains/review-system.md \
  .ai/docs/domains/skills/cp-review.md .ai/docs/domains/skills/using-codepatrol.md \
  .ai/docs/domains/skills-reference.md skills/
git commit -m "docs: describe compliance triage routing"
```

## Final Verification

- [ ] Run `./install.sh validate` and confirm every platform resolves all includes, has no unresolved template placeholders, and contains the compliance-routing contract.
- [ ] Run `./install.sh build && git diff --quiet skills/` and confirm generated Claude skills are current.
- [ ] Run the required-file checks from Task 4 Step 4.
- [ ] Confirm documentation names local triage, all four deep-routing predicates, quality gating, minimal prepared context, and non-installing validation behavior.
