---
name: cpdocs
description: Update AI-oriented project docs from README-based navigation with validation and handoff support
---

# /cpdocs

Update AI-facing project documentation without turning docs into a dump of temporary task context.

## Role

Act as AI project memory maintainer and documentation orchestrator.

Must:
- document only stable, final project knowledge
- keep docs modular and suitable for targeted reading by future agents
- use Markdown + Mermaid by default unless project rules require otherwise

Must not:
- carry temporary task reasoning into `.ai/docs`
- document assumptions as facts
- read all `.ai/docs/` and all code by default
- break README-based navigation

## Runtime Flow

1. Determine intent and scope
2. Decide whether to continue in the current session or hand off to a new one
3. Run docs research from `.ai/docs/README.md` if it exists
4. Read relevant task artifacts and final code state
5. Plan documentation updates
6. Apply changes to docs
7. Run docs validation pass
8. Update workflow state if inside a task flow

## Research Entry

If `.ai/docs/README.md` exists, start from it to decide which docs are relevant.
If it does not exist, skip docs-based research and work from project rules, CLAUDE.md/AGENTS.md, and the actual code.

Read only the targeted docs, then the final task artifacts and the final code needed for the documentation change.

## Supported Modes

- **task workflow mode** — update docs after completing a workflow task; inferred when an active task with completed code path exists
- **whole-project mode** — review and update docs for the entire project; inferred when user asks to "update all docs" or no specific scope is given and no active task exists
- **scoped mode** — update docs for specific files, directories, or areas; inferred when user specifies a target
- **check mode** — verify existing docs for accuracy without editing; inferred from intents like "check docs", "verify documentation"
- **update mode** — update docs for uncommitted changes, branch diffs, or specific code changes; inferred from intents like "update docs for my changes", "document what changed between branches"

Infer the mode from user intent and project state. Ask only when multiple modes fit equally well.

## No-Argument Behavior

When invoked without arguments, infer intent from context:
- if a workflow task is active and code path is complete, update docs for that task
- if `.ai/docs/` does not exist, offer to initialize it
- if recent code changes exist but no active task, offer to update docs for those changes

Ask only when intent remains ambiguous after inference.
When asking, offer concrete options, not open-ended questions.

## Documentation Rules

- document stable, reusable project knowledge
- keep README-based navigation intact
- place docs in `.ai/docs/domains/` or `.ai/docs/shared/` as appropriate
- follow project-facing artifact language resolution:
  - explicit project language rules first
  - then active agent or client language rules
  - English fallback

## Initialization

If `.ai/docs/` does not exist and the mode requires it:
- create `.ai/docs/README.md`, `.ai/docs/domains/`, `.ai/docs/shared/`
- populate README.md as a navigation entry point
- use project rules, CLAUDE.md/AGENTS.md, and actual code as sources for initial documentation

## Doc File Format

Each doc file in `.ai/docs/` should be AI-friendly and include:
- purpose — what this doc covers
- when to read — which tasks or questions make this doc relevant
- scope — boundaries of the documented area
- related docs — links to other relevant docs
- key modules and components
- relationships and dependencies
- constraints and rules
- change impact — what breaks if this area changes
- source of truth references — links to authoritative code, configs, or specs

Default format: Markdown with Mermaid diagrams.
Use C4-lite structuring when it helps, but it is not mandatory for every file.

Useful diagram types by default:
- DFD
- Sequence
- module relationship diagrams

Project rules and existing project conventions override these defaults.

## Session Handoff

Choose whether to continue in the current session or hand off to a new one.

Prefer current session when:
- relevant context is still fresh
- documentation scope is limited
- the change is safe to continue without context reset

Prefer new session when:
- code execution consumed a large amount of context
- the docs update is broad
- a clean documentation-focused pass is safer

Provide a reasoned recommendation, but leave the final choice to the user.
If handing off, provide a short `/cpdocs <artifact-path>` command and keep the workflow state accurate.

## Docs Validation Pass

Before completion, verify:
- `.ai/docs/README.md` still routes readers correctly
- new docs are linked from navigation when needed
- doc placement is coherent
- docs match the final code and task outcome
- the result remains suitable for targeted reading

## Progress Tracking

Use TodoWrite to track documentation progress:
- create a todo for each runtime flow step
- mark as in_progress when working on it
- mark as completed when done

## Blocker Policy

Stop and ask the user when:
- documentation scope or source of truth cannot be reliably determined
- a conflict exists between code, task artifacts, and existing `.ai/docs`
- the intent behind a docs change is ambiguous after inference

Do not continue on assumptions when the risk of documenting wrong information is high.

When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Completion Criteria

This stage is complete only after the docs validation pass succeeds and workflow state is updated.

After `/cpdocs` completes, the workflow task is fully complete.
Do not automatically clean up branches, worktrees, or execution environment unless explicitly decided.
Post-workflow actions (merge, PR, branch retention, cleanup) should be either already resolved or left as an explicit post-workflow decision.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
