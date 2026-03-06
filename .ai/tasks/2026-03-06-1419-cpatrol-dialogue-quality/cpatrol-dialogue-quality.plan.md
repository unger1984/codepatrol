# Plan: cpatrol dialogue quality

- Design: `cpatrol-dialogue-quality.design.md`
- Task slug: `cpatrol-dialogue-quality`
- Goal: Improve dialogue quality in cpatrol sections 2b, 3, 4, 4b + add Dialogue Principles
- Scope: `templates/cpatrol/SKILL.md` only (skills/ regenerated via build)
- Execution mode: single session
- Execution model: current session model
- Constraints: skill text in English, no shared partials, preserve small-task efficiency
- Commit strategy: single commit after all edits + build

## Stages

### Stage 1: Edit template

Objective: Apply all 5 changes from design to `templates/cpatrol/SKILL.md`.

Steps:
1. Expand section 2b — add dialogue depth table after existing complexity definitions
2. Rewrite section 3 — replace current 2-line content with dialogue discipline rules
3. Expand section 4 — add recommendation-first guidance
4. Rewrite section 4b — add incremental validation and hard gate
5. Add Dialogue Principles block before Completion Criteria

Verification: Read the modified template, confirm coherence and no broken placeholders.

### Stage 2: Build and verify

Objective: Regenerate skills/ and verify output.

Steps:
1. Run `./install.sh build`
2. Verify generated `skills/cpatrol/SKILL.md` has all changes with placeholders resolved
3. Verify YAML frontmatter has no unquoted colons (Codex compatibility)

Verification: Build succeeds, frontmatter is valid YAML.

### Stage 3: Commit

Objective: Commit all changes.

Steps:
1. `git add templates/cpatrol/SKILL.md skills/cpatrol/SKILL.md`
2. Commit with descriptive message

Verification: `git status` clean for tracked files.
