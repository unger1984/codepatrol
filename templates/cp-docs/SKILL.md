---
name: cp-docs
description: Use to create or update project documentation, add diagrams, or describe architecture
---

# /cp-docs

Create and maintain AI-facing project documentation from natural language requests.

## Progress Tracking (mandatory)

Before starting work, you MUST create {{PROGRESS_TOOL}} items for each runtime flow step.
Mark each as `in_progress` when working on it and `completed` when done.
This provides visual progress to the user.

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

## No-argument behavior

When invoked without arguments, follow this cascade:

1. **No `.ai/docs/README.md`** (missing or empty/broken — no navigable links) → offer to initialize project documentation
2. **Uncommitted changes exist** (`git diff --name-only HEAD` + untracked) → offer to check/update docs for those changes, show the file list
3. **On a non-main branch with committed changes vs main** → offer to check/update docs for the branch diff, show the changed files
4. **None of the above** → ask the user with concrete options (e.g., document a specific area, audit existing docs, add a new doc)

Stop at the first matching condition. Do not fall through silently.

## Intent Resolution

Produces a brief for the runtime flow.

### Step 1 — Parse intent

Understand from the user's phrase:
- **action** — what to do: create, augment, restructure, or check
- **subject** — what to document: project structure, data flow, specific module, API, etc.
- **format hints** — if the phrase mentions diagrams, tables, or specific Mermaid types

If the phrase is unclear, ask the user to clarify. Offer concrete interpretations, not open-ended questions.

### Step 2 — Read docs structure

Read `.ai/docs/README.md` to understand existing documentation and navigation structure. This is mandatory when `.ai/docs/` exists, even for narrow-scope requests — the skill must know where the new content fits. If `.ai/docs/` does not exist, skip this step and note that initialization is needed before writing.

### Step 3 — Scope decomposition

Evaluate whether the phrase describes one topic or several.

If multiple topics and grouping is ambiguous, ask the user with concrete options:
- one overview document covering all topics
- separate documents per topic
- grouped by theme (with suggested grouping)

Single-topic requests skip this step.

### Step 4 — Target resolution

For each unit from step 3, determine:
- augment an existing file, or create a new one?

Decide autonomously when the answer is clear. Ask the user with options only when the topic partially overlaps an existing document and both augmenting and creating are reasonable.

### Step 5 — Research decision

- **Narrow scope** (single file, one topic) — research inline in the main context
- **Broad scope** (multiple files, cross-cutting topic) — dispatch a research subagent

## Model Policy

Applies only when dispatching a research subagent for broad-scope requests.

{{@include:_shared/model-policy.md}}

{{@include:_shared/subagent-limits.md}}

{{DISPATCH_RESEARCHER}}

**Researcher prompt:**

{{@include:_shared/researcher.md}}

**Query construction:** include subject description, scope, and relevant paths from docs structure. The researcher will read project code, configs, and `.ai/docs/` files as needed.

## Runtime Flow

The flow has two phases: **analysis** (reasoning) and **writing** (mechanical I/O). Do not mix them.

### Analysis phase
1. **Brief formation** — via Intent Resolution (interactive when ambiguous)
2. **Research** — collect information from the project codebase; scope-aware: subagent for broad, inline for narrow
3. **Read relevant code and configs** — targeted reading based on brief and research results
4. **Prepare drafts** — for each target doc, prepare exact content: what to add, update, or restructure

### Writing phase
5. **Apply drafts** — write prepared content to doc files; no new reasoning
6. **Validate** — run scope-aware validation pass

Complete all analysis and draft preparation before writing any file.

## Research Entry

If `.ai/docs/README.md` exists, start from it to decide which docs are relevant.
If it does not exist, skip docs-based research and work from project rules (`{{RULES_SOURCE}}`) and the actual code.

Read only the targeted docs, then the relevant code needed for the documentation change.

## Documentation Rules

- document stable, reusable project knowledge
- keep README-based navigation intact
- place docs in `.ai/docs/domains/` or `.ai/docs/shared/` as appropriate
- follow project-facing artifact language resolution:
  - explicit project language rules first
  - then active agent or client language rules
  - English fallback

## Initialization

Initialization is part of the **Writing phase** — it happens at the start of step 5, before any doc file writes. Research (analysis phase) proceeds without docs context when `.ai/docs/` does not exist.

If `.ai/docs/` does not exist:
- save files using the Write tool — it creates parent directories automatically. Do not use shell commands (`mkdir`, `New-Item`) to create directories. Target directories: `.ai/docs/`, `.ai/docs/domains/`, `.ai/docs/shared/`
- populate README.md as a navigation entry point
- use project rules from `{{RULES_SOURCE}}` and actual code as sources for initial documentation

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

### Table of Contents

Every documentation file must start with a table of contents (after the title). Use Markdown anchor links so that each entry navigates to the corresponding section.

```markdown
## Table of Contents
- [Section Name](#section-name)
- [Another Section](#another-section)
  - [Subsection](#subsection)
```

Generate the ToC from actual headings in the document. Update it whenever sections are added, removed, or renamed.

### Cross-Document Links

When a document references another document, use a relative Markdown link — not a plain text mention.

```markdown
<!-- correct -->
See [Architecture Overview](./domains/architecture.md) for details.

<!-- wrong -->
See the Architecture Overview document for details.
```

All cross-document references must be navigable links. This applies to:
- related docs section
- inline references to other docs
- source of truth references when pointing to other `.ai/docs/` files

Default format: Markdown with Mermaid diagrams.
Use C4-lite structuring when it helps, but it is not mandatory for every file.

### Diagrams

Documentation is read by both AI agents and humans. Diagrams make complex relationships visible at a glance — use them actively, not only when explicitly requested.

**When to add a Mermaid diagram:**
- interaction between 3+ components or services
- data flow across system boundaries
- request/response sequences with multiple steps
- state machines or lifecycle transitions
- dependency graphs between modules

**When a diagram is NOT needed:**
- simple A-calls-B relationships — a sentence is enough
- configuration or list-style documentation
- the same information is already clear from a short paragraph

**Diagram types by context:**
- Architecture, module relationships → flowchart or C4-style
- API calls, multi-step processes → sequence diagram
- Data flow → DFD
- State transitions → state diagram

**User-requested documentation** (ad hoc mode) has the highest likelihood of benefiting from diagrams — the user is trying to understand something, and a visual overview helps. Default to including at least one diagram unless the topic is purely list-based.

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
If handing off, provide a short `/cp-docs <artifact-path>` command and keep the workflow state accurate.

## Docs Validation Pass

Scope-aware validation before completion.

**Always (any scope):**
- `.ai/docs/README.md` correctly references changed and new files
- content matches the actual code
- every changed/new file has a table of contents matching its headings
- all cross-document references are navigable relative links (no plain text mentions)

**Broad scope (new documents, multiple files):**
- full navigation integrity — no orphan docs, no broken links
- placement coherence — domain vs shared
- cross-document links are bidirectional where appropriate

**Narrow scope (augmenting a single file):**
- changed section is consistent with the rest of the file
- table of contents is updated to reflect any heading changes

## Blocker Policy

Stop and ask the user when:
- documentation scope or source of truth cannot be reliably determined
- a conflict exists between code and existing `.ai/docs`
- the intent behind a docs change is ambiguous after inference

Do not continue on assumptions when the risk of documenting wrong information is high.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Read all `.ai/docs/` and all code by default** — start from README.md, follow navigation, read only what is needed
- **Carry temporary task reasoning into `.ai/docs`** — document only stable, final project knowledge
- **Document assumptions as facts** — verify against actual code before writing
- **Break README-based navigation** — every doc change must keep navigation intact
- **Mix analysis and writing phases** — complete all analysis before writing any file
- **Write docs without running the validation pass** — no completion without validation

## Completion Criteria

This skill is complete only after the docs validation pass succeeds.

After docs validation pass succeeds, the work is complete. Present the user with a summary of what was updated.
