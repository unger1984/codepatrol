---
name: cpdocs
description: Update AI-oriented project docs from README-based navigation with validation and handoff support
---

# /cpdocs

Update AI-facing project documentation without turning docs into a dump of temporary task context.

## Research Entry

Always start from `.ai/docs/README.md`.

Use it to decide which docs are relevant. Read only the targeted docs, then the final task artifacts and the final code needed for the documentation change.

## Supported Modes

- task workflow mode
- whole-project mode
- scoped mode
- check mode
- update mode

If intent or scope is unclear, ask before editing docs.

## Documentation Rules

- document stable, reusable project knowledge
- keep README-based navigation intact
- place docs in `.ai/docs/domains/` or `.ai/docs/shared/` as appropriate
- follow project-facing artifact language resolution:
  - explicit project language rules first
  - then active agent or client language rules
  - English fallback

## Session Handoff

Choose whether to continue in the current session or hand off to a new one.

Prefer handoff when:
- code execution consumed a large amount of context
- the docs update is broad
- a clean documentation-focused pass is safer

If handing off, provide a short `/cpdocs <artifact-path>` command and keep the workflow state accurate.

## Docs Validation Pass

Before completion, verify:
- `.ai/docs/README.md` still routes readers correctly
- new docs are linked from navigation when needed
- doc placement is coherent
- docs match the final code and task outcome
- the result remains suitable for targeted reading

## Completion Criteria

This stage is complete only after the docs validation pass succeeds and workflow state is updated.
