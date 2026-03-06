# cpdocs ad hoc mode — Design & Plan

## Problem

`/cpdocs` works well in workflow mode (after task completion) but cannot handle free-form requests like `/cpdocs "добавь документацию по структуре проекта"`. Users need a natural-language interface to create and augment `.ai/docs/` documentation on demand.

## Approach: Ad Hoc as Preprocessor (Brief Pattern)

Both modes (workflow and ad hoc) produce an internal **brief** before entering the shared flow. Workflow mode builds the brief from task artifacts (self-directed, no questions). Ad hoc mode builds it by parsing the user's phrase (asks when ambiguous).

### Brief Structure (internal, not persisted)

| Field | Description |
|-------|-------------|
| action | create / augment / restructure / check |
| subject | what to document (project structure, data flow, module X…) |
| target | file path in `.ai/docs/` or `auto` |
| scope | narrow (single file) / broad (multiple files) |
| format_hints | diagram type, table, text — if mentioned in phrase |

### Ad Hoc Intent Resolution (new block, only in ad hoc mode)

1. **Parse intent** — understand action, subject, format_hints from phrase
2. **Read docs structure** — read `.ai/docs/README.md` to know existing docs and navigation; if `.ai/docs/` missing — note for initialization
3. **Scope decomposition** — if phrase describes multiple topics, determine grouping; ask user with concrete options when ambiguous (one overview doc vs separate docs vs grouped)
4. **Target resolution** — for each unit from step 3: augment existing file or create new? Ask with options only when ambiguous (topic partially overlaps existing doc)
5. **Research decision** — narrow scope: research inline; broad scope: dispatch subagent (default tier, model policy applies)

Workflow mode skips steps 1-4 entirely — brief comes from task artifacts, skill decides autonomously.

### Model Policy

Applied only for research subagent dispatch (broad scope). Uses `{{@include:_shared/model-policy.md}}`. Writing stays in orchestrator context — not worth the complexity of dispatching to a cheaper model.

### Unified Runtime Flow (replaces current)

1. **Mode detection** — active workflow task? → workflow mode; otherwise → ad hoc mode
2. **Brief formation** — workflow: from artifacts; ad hoc: via Intent Resolution
3. **Research** — scope-aware: subagent for broad, inline for narrow; data collected from entire project
4. **Read relevant code/configs**
5. **Prepare drafts** — exact content for each target file
6. **Write** — apply drafts, no new reasoning
7. **Validate** — scope-aware (see below)
8. **Update workflow state** — only in workflow mode

### Scope-Aware Validation

**Always:**
- `.ai/docs/README.md` correctly references changed/new files
- content matches code

**Broad scope only:**
- full navigation integrity (no orphans, no broken links)
- placement coherence (domain vs shared)

**Narrow scope only:**
- changed section consistent with rest of the file

## Changes to Template

### Added
- **Mode Detection** section (~5 lines) — before Runtime Flow
- **Ad Hoc Intent Resolution** section (~25 lines) — steps 1-5
- **Brief Formation** section (~5 lines) — two paths, workflow autonomous / ad hoc interactive
- **Model Policy** reference — `{{@include:_shared/model-policy.md}}` with note: applies only to research subagent for broad scope
- **Research Decision** logic in research section — inline vs subagent

### Modified
- **Runtime Flow** — rewritten as unified flow with two entry paths
- **Supported Modes** — removed 5 named modes, replaced with two entry paths (workflow/ad hoc) + dynamic action/subject/scope
- **No-Argument Behavior** — simplified, merged into mode detection
- **Docs Validation Pass** — scope-aware validation

### Unchanged
- Doc File Format
- Initialization
- Session Handoff
- Blocker Policy
- Completion Criteria
- Progress Tracking

### Estimated size delta
+30-35 lines added, -10 lines from Supported Modes removal. Net growth: ~20-25 lines.

---

## Implementation Plan

### Stage 1: Rewrite Runtime Flow structure

Rewrite the Runtime Flow section in `templates/cpdocs/SKILL.md`:
- Add Mode Detection block
- Add Brief Formation block (two paths)
- Rewrite Analysis/Writing phases as unified steps 1-8

**Verify:** template reads coherently top to bottom, no contradictions.

### Stage 2: Add Ad Hoc Intent Resolution

Add new section after Mode Detection:
- Steps 1-5 (parse, docs structure, scope decomposition, target resolution, research decision)
- Clarification behavior: ask with concrete options, only when ambiguous

**Verify:** re-read section, check it handles edge cases (multi-topic phrase, empty `.ai/docs/`, single diagram request).

### Stage 3: Add Model Policy for research subagent

Add `{{@include:_shared/model-policy.md}}` reference with scope note (broad research only).

**Verify:** consistent with how cpatrol uses model-policy.md.

### Stage 4: Rework Supported Modes and No-Argument Behavior

- Remove 5 named modes, replace with workflow/ad hoc entry paths
- Merge No-Argument Behavior into Mode Detection

**Verify:** no orphaned references to old mode names.

### Stage 5: Update Docs Validation Pass

Replace flat checklist with scope-aware validation (always / broad / narrow).

**Verify:** narrow scope still checks README references.

### Stage 6: Build and sanity check

Run `./install.sh build`, read generated `skills/cpdocs/SKILL.md`, verify:
- All placeholders resolved
- Includes inlined
- No broken references
- Template reads as coherent instruction set

### Commit strategy

Single commit after all stages pass verification.
