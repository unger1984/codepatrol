# Design: Compatibility Review Dimension

## Task Objective

Add a 5th review dimension "Compatibility" to cp-review skill that detects deprecated API usage, version compatibility issues, and breaking changes in dependencies. Project rules can whitelist specific deprecated items or disable the check entirely.

## Research Summary

- cp-review has a two-pass model: Compliance (mandatory) + Quality (4 dimensions)
- Quality dimensions: Architecture, Security, Testing, Conventions — each with a dedicated reviewer prompt file
- All reviewer prompts follow identical format: Title, Inputs ({FILES}, {PROJECT_RULES}, {DESIGN_DOC}), Checklist, Guidance, Output template
- Severity levels: Critical, Important, Minor
- Build system copies all `*.md` files from `templates/cp-review/` to `skills/cp-review/` unchanged
- Reviewer prompts are standalone files, NOT included via `{{@include:}}` directives
- Subagent dispatch references reviewers by dimension name; adding a new dimension requires no structural changes to SKILL.md core logic

## Constraints and Relevant Rules

- Templates must be universal — no hardcoded languages, frameworks, or project-specific data
- Skill file content in English
- After editing templates, run `./install.sh build`
- Every reviewer must use standardized Output format with Severity, File, Finding type, Area, Problem, Why it matters, Fix fields

## Considered Approaches

### A. Add to existing Conventions dimension
- Pro: No new file, minimal changes
- Con: Conventions reviewer already covers naming, formatting, structure — adding compatibility there conflates concerns
- **Rejected:** conceptually different category

### B. New Compatibility dimension (chosen)
- Pro: Clean separation of concerns, dedicated checklist, independent tier assignment
- Con: One more subagent dispatch (negligible cost at fast tier)
- **Chosen:** aligns with existing pattern, extensible

## Chosen Approach

New "Compatibility" dimension as 5th quality pass reviewer.

## Solution Outline

### 1. New file: `templates/cp-review/compatibility-reviewer.md`

Structure mirrors existing reviewers (codestyle-reviewer.md as reference):

```
# Compatibility Reviewer

You review compatibility for `/cp-review`.

## Inputs
- {FILES}
- {PROJECT_RULES}
- {DESIGN_DOC}

## Checklist

### Deprecated API
- [ ] No usage of deprecated functions, classes, methods, or modules from libraries, frameworks, or language standard library
- [ ] If a deprecated item is used, a modern replacement is available and documented
- [ ] No reliance on behavior that is deprecated but not yet removed

### Version Compatibility
- [ ] APIs used match the versions declared in project dependencies (package.json, requirements.txt, go.mod, etc.)
- [ ] No usage of APIs introduced in versions newer than the project's minimum supported version
- [ ] No usage of APIs removed in the project's target version range

### Breaking Changes Awareness
- [ ] Code does not depend on undocumented or internal APIs of dependencies
- [ ] No patterns known to break on minor/patch version updates of dependencies

## Guidance
- Default severity: Minor (deprecated API is not an immediate blocker)
- Escalate to Important if the deprecated API has a announced removal timeline in an upcoming major version
- Escalate to Critical only if the deprecated API is already removed in the version declared in project dependencies
- Always provide the recommended replacement in the Fix field
- If project rules explicitly allow specific deprecated APIs or disable compatibility checks entirely, skip those findings
- Do not report deprecated usage in test fixtures or compatibility shims explicitly marked as intentional

## Output
(standard reviewer output format)
```

### 2. Changes to `templates/cp-review/SKILL.md`

- Add Compatibility to the dimensions list/table alongside existing 4 dimensions
- Starting tier: `fast` (same as Conventions — model knowledge is sufficient, no heavy reasoning needed)
- Add to subagent dispatch instructions for medium/large scope
- Add rules override note: "If project rules explicitly allow specific deprecated APIs or disable compatibility checks — the Compatibility reviewer skips those findings"

### 3. Documentation updates

- `.ai/docs/domains/review-system.md` — add Compatibility to dimensions list
- `.ai/docs/domains/skills/cp-review.md` — add Compatibility description

### 4. Build

- `./install.sh build` to regenerate `skills/`

## Execution Strategy

- **Plan generation:** `/cp-plan` → `/cp-plan-review` → `/cp-plan-fix`
- **Execution:** `/cp-execute` — task is small, any model tier works
- **Granularity:** fine-grained (small task, few files)

## Impact Analysis

- **New file:** 1 (`compatibility-reviewer.md`)
- **Modified files:** 1 template (`SKILL.md`), 2 docs
- **Risk:** Low — additive change, no existing behavior modified
- **Backward compatibility:** Full — existing reviews unaffected, new dimension adds findings

## Assumptions

- Model (LLM) has sufficient training data knowledge about deprecated APIs in popular libraries/frameworks
- No external tooling or linting integration needed — purely prompt-based detection
- Project rules are read by the reviewer subagent via `{PROJECT_RULES}` placeholder (already works for other dimensions)

## Open Questions

None — all questions resolved during clarification.
