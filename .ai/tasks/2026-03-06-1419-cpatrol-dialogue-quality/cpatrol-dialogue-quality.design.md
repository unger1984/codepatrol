# Design: cpatrol dialogue quality

## Objective

Improve clarification, approach options, and solution outline stages in cpatrol to match brainstorming skill's dialogue quality while preserving cpatrol's strengths (complexity classification, research-first, efficiency).

## Research Summary

Brainstorming excels at: one question at a time, multiple choice preference, recommendation-first approaches, incremental validation, hard gate before implementation, explicit key principles.

cpatrol excels at: research-first with subagent, task complexity classification (small/medium/large), efficiency-oriented clarification, integrated planning, session mode heuristic.

## Constraints

- Skill text must be in English
- Changes are inline (approach 1) — no shared partials
- Dialogue depth must scale with task complexity classification
- Must not degrade small-task efficiency
- Template uses `{{PLACEHOLDER}}` syntax for platform-specific values

## Chosen Approach

Inline expansion of sections 2b, 3, 4, 4b + new Dialogue Principles block.

## Changes

### 1. Section 2b — add dialogue depth scaling

After existing complexity definitions, add a table mapping complexity to dialogue depth:

| Aspect | small | medium | large |
|--------|-------|--------|-------|
| Questions | 1-2 max, infer the rest | Full discipline, one at a time | Full discipline, one at a time |
| Approaches | Single recommendation with brief rationale | 2-3 with trade-offs, lead with recommendation | 2-3 with structured comparison, lead with recommendation |
| Outline | Few sentences, still requires confirmation | Section-by-section with validation | Section-by-section with validation + diagrams |

### 2. Section 3 — rewrite "Clarify Only What Matters" to "Clarify Through Dialogue"

New content:
- One question at a time, wait for response
- Prefer multiple choice with "other" option
- Infer obvious intent — but ask when ambiguity affects scope, architecture, or strategy
- Questions should build on research findings, not ask what research already answered
- For small tasks: 1-2 questions max, then move on

### 3. Section 4 — expand "Offer Realistic Approaches"

New content:
- Lead with recommended option and explain WHY
- Then present 1-2 alternatives with trade-offs
- Be explicit about what you'd lose and gain with each
- For small tasks: single recommendation with brief rationale is sufficient
- Do not present options without a recommendation

### 4. Section 4b — add incremental validation and hard gate

New content:
- Present outline in logical sections
- After each section, ask whether it looks right before continuing
- Scale section depth to complexity
- User may refine multiple times — update outline, show diff, update trade-offs
- Hard gate: do NOT suggest moving to design until user explicitly confirms the full outline
- For small tasks: outline can be compact but confirmation is still required

### 5. New block: Dialogue Principles (before Completion Criteria)

Six principles:
1. One question at a time
2. Multiple choice preferred
3. Recommend, don't just list
4. Incremental validation
5. YAGNI
6. Ask first, act second

## Impact Analysis

- Sections 3, 4, 4b grow in size but remain focused
- Section 2b gets a complexity-dialogue table (~6 lines)
- New Dialogue Principles block (~12 lines)
- Total template growth: ~40-50 lines
- No changes to workflow file format, stage tracking, or model policy
- No changes to other skills

## Assumptions

- The `{{ASK_USER}}` placeholder is sufficient for platform-specific question mechanism
- Complexity classification happens before clarification (confirmed: 2b is before 3)
