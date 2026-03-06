# AI Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current `code-review` / `code-review-fix` skill system with the new workflow-first command surface and template-driven multi-platform skill set described in the approved design.

**Architecture:** The new system keeps a single source of truth in `templates/`, isolates platform differences in `platforms/*.env`, and regenerates `skills/` as disposable build output. User-facing commands become `/cpatrol`, `/cpresume`, `/cpexecute`, `/cpreview`, `/cpfix`, `/cpplanreview`, `/cpplanfix`, `/cpdocs`, and `/cprules`, while internal skills, prompts, and stage identifiers stay English-only and hidden from users.

**Tech Stack:** Bash installer (`install.sh`), Markdown skill templates, environment placeholder substitution via `platforms/*.env`, Claude plugin manifests, generated local skill directories.

---

### Task 1: Replace Template Topology

**Files:**
- Create: `templates/cpatrol/SKILL.md`
- Create: `templates/cpresume/SKILL.md`
- Create: `templates/cpexecute/SKILL.md`
- Create: `templates/cpplanreview/SKILL.md`
- Create: `templates/cpplanfix/SKILL.md`
- Create: `templates/cpreview/SKILL.md`
- Create: `templates/cpreview/architecture-reviewer.md`
- Create: `templates/cpreview/codestyle-reviewer.md`
- Create: `templates/cpreview/security-reviewer.md`
- Create: `templates/cpreview/testing-reviewer.md`
- Create: `templates/cpfix/SKILL.md`
- Create: `templates/cpfix/fix-agent-prompt.md`
- Create: `templates/cpdocs/SKILL.md`
- Create: `templates/cprules/SKILL.md`
- Delete: `templates/code-review/SKILL.md`
- Delete: `templates/code-review/architecture-reviewer.md`
- Delete: `templates/code-review/codestyle-reviewer.md`
- Delete: `templates/code-review/security-reviewer.md`
- Delete: `templates/code-review/testing-reviewer.md`
- Delete: `templates/code-review-fix/SKILL.md`
- Delete: `templates/code-review-fix/fix-agent-prompt.md`

**Step 1: Create the failing structural check**

Run:
```bash
test -d templates/cpatrol && test -d templates/cpreview && test -d templates/cpfix && test -d templates/cpdocs && test -d templates/cprules
```
Expected: FAIL because the new template directories do not exist yet.

**Step 2: Create the new template directories and seed files**

Implement minimal placeholder template files for each approved command family listed above. Keep all reusable instructions in English and do not copy old command names into user-facing examples.

**Step 3: Remove legacy template directories**

Delete the old `templates/code-review/` and `templates/code-review-fix/` trees after the new directories exist so the build cannot regenerate legacy skill names.

**Step 4: Verify template topology**

Run:
```bash
find templates -maxdepth 2 -type f | sort
```
Expected: PASS with only the new `cp*` and `cpatrol` template trees present.

**Step 5: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.

### Task 2: Implement Core Workflow Entry Skills

**Files:**
- Modify: `templates/cpatrol/SKILL.md`
- Modify: `templates/cpresume/SKILL.md`
- Modify: `templates/cpexecute/SKILL.md`
- Test: `docs/plans/2026-03-06-ai-workflow-design.md`

**Step 1: Write the failing content check**

Run:
```bash
rg -n "^name: (cpatrol|cpresume|cpexecute)$|/cpatrol|/cpresume|/cpexecute" templates/cpatrol/SKILL.md templates/cpresume/SKILL.md templates/cpexecute/SKILL.md
```
Expected: FAIL or partial output because the seeded templates are incomplete.

**Step 2: Implement `templates/cpatrol/SKILL.md`**

Cover:
- workflow-first entry behavior
- unfinished-task warning
- research -> clarification -> options -> design -> plan ready flow
- user-facing command language following active client/agent language rules
- internal technical names hidden from users

**Step 3: Implement `templates/cpresume/SKILL.md`**

Cover:
- artifact-driven resume from `workflow.md`, `design.md`, `plan.md`, and reports
- automatic phase detection
- user-facing display names instead of technical stage identifiers

**Step 4: Implement `templates/cpexecute/SKILL.md`**

Cover:
- explicit execution by `plan.md`
- execution preflight
- branch safety
- checkpoint reporting
- handoff into `/cpreview`

**Step 5: Verify core entry skills**

Run:
```bash
rg -n "^name: (cpatrol|cpresume|cpexecute)$|/cpatrol|/cpresume|/cpexecute|execution preflight|unfinished" templates/cpatrol/SKILL.md templates/cpresume/SKILL.md templates/cpexecute/SKILL.md
```
Expected: PASS with the expected command names and workflow responsibilities present.

**Step 6: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.

### Task 3: Implement Plan Review and Plan Fix Skills

**Files:**
- Modify: `templates/cpplanreview/SKILL.md`
- Modify: `templates/cpplanfix/SKILL.md`
- Test: `docs/plans/2026-03-06-ai-workflow-design.md`

**Step 1: Write the failing content check**

Run:
```bash
rg -n "^name: (cpplanreview|cpplanfix)$|/cpplanreview|/cpplanfix|plan review|bounded revalidation" templates/cpplanreview/SKILL.md templates/cpplanfix/SKILL.md
```
Expected: FAIL or partial output.

**Step 2: Implement `templates/cpplanreview/SKILL.md`**

Cover:
- plan review against project rules, design, execution model, verification, docs impact
- English-only internal instructions
- user-facing command examples with new command names

**Step 3: Implement `templates/cpplanfix/SKILL.md`**

Cover:
- fixing open plan-review findings
- auto-fix vs ask-user behavior
- bounded revalidation
- report mutation and resumability

**Step 4: Verify plan-skill content**

Run:
```bash
rg -n "^name: (cpplanreview|cpplanfix)$|/cpplanreview|/cpplanfix|revalidation|ask-user|auto-fix" templates/cpplanreview/SKILL.md templates/cpplanfix/SKILL.md
```
Expected: PASS.

**Step 5: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.

### Task 4: Implement Code Review and Review Fix Skills

**Files:**
- Modify: `templates/cpreview/SKILL.md`
- Modify: `templates/cpreview/architecture-reviewer.md`
- Modify: `templates/cpreview/codestyle-reviewer.md`
- Modify: `templates/cpreview/security-reviewer.md`
- Modify: `templates/cpreview/testing-reviewer.md`
- Modify: `templates/cpfix/SKILL.md`
- Modify: `templates/cpfix/fix-agent-prompt.md`

**Step 1: Write the failing content check**

Run:
```bash
rg -n "^name: (cpreview|cpfix)$|/cpreview|/cpfix|compliance pass|quality pass" templates/cpreview/SKILL.md templates/cpfix/SKILL.md
```
Expected: FAIL or partial output.

**Step 2: Implement `templates/cpreview/SKILL.md`**

Cover:
- new command name `/cpreview`
- scope modes that are still relevant in the new system
- compliance pass before quality pass
- saving reports under workflow/report conventions

**Step 3: Adapt reviewer prompts under `templates/cpreview/`**

Rename or rewrite the reviewer prompts so they reference the new skill family and no longer mention `code-review`.

**Step 4: Implement `templates/cpfix/SKILL.md`**

Cover:
- new command name `/cpfix`
- processing findings from `/cpreview`
- prioritizing compliance findings before quality findings
- optional alternative fixes and report mutation

**Step 5: Implement `templates/cpfix/fix-agent-prompt.md`**

Ensure it uses the new paths, new skill family names, and language-policy-compatible comments behavior.

**Step 6: Verify review/fix skill content**

Run:
```bash
rg -n "/code-review|/code-review-fix|code-review|code-review-fix" templates/cpreview templates/cpfix
```
Expected: FAIL with no matches.

Run:
```bash
rg -n "^name: (cpreview|cpfix)$|/cpreview|/cpfix|compliance pass|quality pass" templates/cpreview/SKILL.md templates/cpfix/SKILL.md
```
Expected: PASS.

**Step 7: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.

### Task 5: Implement Docs and Rules Skills

**Files:**
- Modify: `templates/cpdocs/SKILL.md`
- Modify: `templates/cprules/SKILL.md`

**Step 1: Write the failing content check**

Run:
```bash
rg -n "^name: (cpdocs|cprules)$|/cpdocs|/cprules|language policy|README-based navigation" templates/cpdocs/SKILL.md templates/cprules/SKILL.md
```
Expected: FAIL or partial output.

**Step 2: Implement `templates/cpdocs/SKILL.md`**

Cover:
- docs research from `.ai/docs/README.md`
- docs validation pass
- session handoff rules
- project-facing artifact language resolution

**Step 3: Implement `templates/cprules/SKILL.md`**

Cover:
- project-rules analysis
- user approval before applying changes
- no automatic rule churn

**Step 4: Verify docs/rules skill content**

Run:
```bash
rg -n "^name: (cpdocs|cprules)$|/cpdocs|/cprules|README|language" templates/cpdocs/SKILL.md templates/cprules/SKILL.md
```
Expected: PASS.

**Step 5: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.

### Task 6: Update Platform Config, Build Flow, and Generated Outputs

**Files:**
- Modify: `platforms/codex.env`
- Modify: `platforms/claude.env`
- Modify: `install.sh`
- Modify: `README.md`
- Modify: `README.ru.md`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Delete: `skills/code-review/SKILL.md`
- Delete: `skills/code-review/architecture-reviewer.md`
- Delete: `skills/code-review/codestyle-reviewer.md`
- Delete: `skills/code-review/security-reviewer.md`
- Delete: `skills/code-review/testing-reviewer.md`
- Delete: `skills/code-review-fix/SKILL.md`
- Delete: `skills/code-review-fix/fix-agent-prompt.md`

**Step 1: Write the failing build check**

Run:
```bash
./install.sh build
```
Expected: FAIL or generate legacy directories until the platform config, template references, and documentation are updated.

**Step 2: Update `platforms/*.env`**

Replace any placeholders, examples, or rule text that still point to `code-review` / `code-review-fix` or old command names. Ensure Codex and Claude differences are still isolated here.

**Step 3: Update `install.sh` behavior if needed**

Keep the current replacement-oriented generation model, but ensure it works with the new template directories and does not leave legacy generated outputs behind.

**Step 4: Update docs and plugin metadata**

Rewrite `README.md`, `README.ru.md`, and plugin metadata so installation and usage instructions expose only the new command surface and skill names.

**Step 5: Regenerate generated skills**

Run:
```bash
./install.sh build
```
Expected: PASS and generate only the new skill directories under `skills/`.

**Step 6: Verify generated output and absence of legacy names**

Run:
```bash
find skills -maxdepth 2 -type f | sort
```
Expected: PASS with only new `cpatrol` / `cp*` skill directories.

Run:
```bash
rg -n "/code-review|/code-review-fix|code-review|code-review-fix" skills README.md README.ru.md .claude-plugin platforms install.sh
```
Expected: FAIL with no matches.

**Step 7: Verify install targets in dry-run style**

Run:
```bash
./install.sh claude
./install.sh codex
```
Expected: PASS, with install output referencing only the new skill directories.

**Step 8: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.

### Task 7: Final Verification Pass

**Files:**
- Verify: `docs/plans/2026-03-06-ai-workflow-design.md`
- Verify: `docs/plans/2026-03-06-ai-workflow-implementation.md`
- Verify: `templates/`
- Verify: `platforms/`
- Verify: `skills/`
- Verify: `README.md`
- Verify: `README.ru.md`
- Verify: `install.sh`
- Verify: `.claude-plugin/plugin.json`
- Verify: `.claude-plugin/marketplace.json`

**Step 1: Run full build verification**

Run:
```bash
./install.sh build
```
Expected: PASS with no errors.

**Step 2: Verify approved command surface**

Run:
```bash
rg -n "/cpatrol|/cpresume|/cpexecute|/cpreview|/cpfix|/cpplanreview|/cpplanfix|/cpdocs|/cprules" templates skills README.md README.ru.md
```
Expected: PASS with the new command surface present.

**Step 3: Verify old command surface is gone**

Run:
```bash
rg -n "/code-review|/code-review-fix|brainstorm|review-plan|fix-review-plan|review-code|fix-review-code|update-ai-docs|update-project-rules" README.md README.ru.md templates skills .claude-plugin
```
Expected: only internal technical references that are explicitly intentional; no legacy user-facing command names.

**Step 4: Verify install flows**

Run:
```bash
./install.sh claude
./install.sh codex
```
Expected: PASS, installing only the new skills.

**Step 5: Manual acceptance check**

Confirm manually:
- the new user-facing commands are consistent across docs and generated skills
- no legacy runtime directories remain under `skills/`
- platform-specific differences still live in `platforms/*.env`
- internal skill/agent names do not leak into user-facing help text

**Step 6: Optional commit checkpoint**

Do not commit unless the user explicitly asks for one.
