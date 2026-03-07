# Plan: Compatibility Review Dimension

- **Design:** deprecated-check.design.md
- **Task slug:** deprecated-check
- **Goal:** Add 5th review dimension "Compatibility" to cp-review skill
- **Scope:** templates/cp-review/, .ai/docs/
- **Execution mode:** sequential (small task, no parallelization needed)
- **Execution model:** any tier (small, well-scoped task)
- **Recommended skills:** /cp-execute
- **Commit strategy:** no commits (manual)
- **Constraints:**
  - Templates must be universal — no hardcoded languages/frameworks
  - Skill file content in English
  - Run `./install.sh build` after template changes
  - Reviewer prompt must follow exact format of existing reviewers (codestyle-reviewer.md as reference)

## Verification Strategy

- `./install.sh build` must succeed
- Generated `skills/cp-review/SKILL.md` must reference Compatibility dimension
- Generated `skills/cp-review/compatibility-reviewer.md` must exist
- Reviewer prompt must have all required sections: Inputs, Checklist, Guidance, Output

## Stage 1: Create compatibility-reviewer.md

**Objective:** Create the Compatibility reviewer prompt template.

**Steps:**
1. Create `templates/cp-review/compatibility-reviewer.md` following the exact structure of `codestyle-reviewer.md`:
   - Title: `# Compatibility Reviewer`
   - Intro: `You review compatibility for /cp-review.`
   - Inputs: `{FILES}`, `{PROJECT_RULES}`, `{DESIGN_DOC}`
   - Checklist with 3 categories:
     - **Deprecated API** — usage of deprecated functions/classes/methods/modules; availability of modern replacement; reliance on deprecated-but-not-removed behavior
     - **Version Compatibility** — APIs match declared dependency versions; no APIs from newer versions than minimum supported; no APIs removed in target range
     - **Breaking Changes Awareness** — no reliance on undocumented/internal APIs; no patterns known to break on minor updates
   - Guidance:
     - Default severity: Minor
     - Escalate to Important if removal timeline announced in upcoming major version
     - Escalate to Critical if deprecated API already removed in declared dependency version
     - Always provide recommended replacement in Fix field
     - Skip findings if project rules explicitly allow specific deprecated APIs or disable compatibility checks
     - Do not report deprecated usage in test fixtures or compatibility shims marked as intentional
   - Output: standard reviewer format with `**Area:** compatibility`
   - Summary: finding count, overall compatibility assessment, what was done well

**Verification:** File exists, all sections present, format matches codestyle-reviewer.md structure.

## Stage 2: Update SKILL.md template

**Objective:** Integrate Compatibility dimension into the review orchestrator template.

**Steps:**
1. Add `- [ ] Compatibility review` to Progress Tracking list (after Conventions review, line 22)
2. Add `- compatibility and deprecated API usage` to Quality Pass description (after security line, around line 97)
3. Add `compatibility` to the dispatch dimension list (line 104)
4. Add `- **Compatibility** → fast` to the Starting tier table (after Conventions, line 113)

**Verification:** All 4 insertion points updated. No existing lines broken.

## Stage 3: Update documentation

**Objective:** Reflect new dimension in AI docs.

**Steps:**
1. Update `.ai/docs/domains/review-system.md` — add Compatibility to dimensions list and description
2. Update `.ai/docs/domains/skills/cp-review.md` — add Compatibility to skill documentation

**Verification:** Both docs mention Compatibility dimension with consistent description.

## Stage 4: Build and verify

**Objective:** Regenerate skills/ and verify output.

**Steps:**
1. Run `./install.sh build`
2. Verify `skills/cp-review/compatibility-reviewer.md` exists
3. Verify `skills/cp-review/SKILL.md` contains all Compatibility references

**Verification:** Build succeeds. Generated files contain expected content.
