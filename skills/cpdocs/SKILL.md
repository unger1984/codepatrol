---
name: cpdocs
description: Use to create or update project documentation, add diagrams, or describe architecture
---

# /cpdocs

Update AI-facing project documentation. Supports both workflow-driven updates and ad hoc requests in natural language.

## Progress Tracking (mandatory)

Before starting work, you MUST create TodoWrite items for each runtime flow step.
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

## Mode Detection

Determine the operating mode before any other work:

- **Workflow mode** — an active workflow task exists with a completed code path. Brief is formed from task artifacts. The skill decides autonomously what and where to document — no clarification questions about scope or target.
- **Ad hoc mode** — no active workflow task. Brief is formed via Intent Resolution from the user's phrase. Asks the user only when genuine ambiguity exists.

When invoked without arguments:
- if a workflow task is active and code path is complete → workflow mode
- if `.ai/docs/` does not exist → offer to initialize it
- if recent code changes exist but no active task → offer to update docs for those changes
- otherwise → ask the user with concrete options

## Ad Hoc Intent Resolution

Applies only in ad hoc mode. Produces a brief for the unified flow.

### Step 1 — Parse intent

Understand from the user's phrase:
- **action** — what to do: create, augment, restructure, or check
- **subject** — what to document: project structure, data flow, specific module, API, etc.
- **format hints** — if the phrase mentions diagrams, tables, or specific Mermaid types

If the phrase is unclear, ask the user to clarify. Offer concrete interpretations, not open-ended questions.

### Step 2 — Read docs structure

Read `.ai/docs/README.md` to understand existing documentation and navigation structure. This is mandatory even for narrow-scope requests — the skill must know where the new content fits.

If `.ai/docs/` does not exist, note that initialization is needed before writing.

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
- **Broad scope** (multiple files, cross-cutting topic) — dispatch research to a subagent

## Model Policy

Applies only when dispatching a research subagent for broad-scope ad hoc requests.

Choose the cheapest model that can handle the task. If the platform supports model selection for subagents, use it.

### Model Tiers

| Tier | Description | Use when |
|------|-------------|----------|
| **fast** | Cheapest/fastest available | Simple, well-scoped tasks with clear instructions |
| **default** | Mid-range | Most subagent work requiring comprehension and judgment |
| **powerful** | Most capable available | Complex reasoning, ambiguous constraints, tasks that failed at a lower tier |

### Ceiling Rule

The current session model is the ceiling. Subagents cannot use a more capable model than the orchestrator.

### User Override

If project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers (e.g., `fast: haiku`, `default: sonnet`), use it. User-defined mapping takes priority over automatic selection.

### Escalation on Failure

If a subagent returns an error, produces empty or unusable output, or fails its task:
1. **Do not retry at the same tier.** Escalate to the next tier up (fast → default → powerful), respecting the ceiling.
2. Re-dispatch the same task with the higher-tier model.
3. Maximum one escalation per subagent. If the ceiling tier fails, treat it as a blocker and ask the user.
4. Log the escalation in the progress update so the user sees it.

Launch reviewers in parallel using Agent tool with `run_in_background=true`. Send all Agent calls in a single message for true parallelism. Use the `model` parameter to set the model tier for each subagent.

Research subagent contract:
- receives: subject description, scope, list of relevant paths from docs structure
- reads: project code, configs, and relevant `.ai/docs/` files — across the entire project
- returns: structured summary (key findings, confirmed facts, assumptions, open questions)
- must not: bulk-read the repository; For file discovery, use Glob, Grep, or MCP filesystem tools if available. Do not fall back to shell commands (find, grep) unless no dedicated tool is available.

## Runtime Flow

The flow has two phases: **analysis** (reasoning) and **writing** (mechanical I/O). Do not mix them.

### Analysis phase
1. **Mode detection** — workflow or ad hoc (see above)
2. **Brief formation** — workflow: from task artifacts (autonomous); ad hoc: via Intent Resolution (interactive when ambiguous)
3. **Research** — collect information from the project codebase; scope-aware: subagent for broad, inline for narrow
4. **Read relevant code and configs** — targeted reading based on brief and research results
5. **Prepare drafts** — for each target doc, prepare exact content: what to add, update, or restructure

### Writing phase
6. **Apply drafts** — write prepared content to doc files; no new reasoning
7. **Validate** — run scope-aware validation pass
8. **Update workflow state** — only in workflow mode

Complete all analysis and draft preparation before writing any file.

## Research Entry

If `.ai/docs/README.md` exists, start from it to decide which docs are relevant.
If it does not exist, skip docs-based research and work from project rules, CLAUDE.md/AGENTS.md, and the actual code.

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

If `.ai/docs/` does not exist and the mode requires it:
- create directories with `mkdir -p` (idempotent — do not check existence separately or ask permission): `.ai/docs/`, `.ai/docs/domains/`, `.ai/docs/shared/`
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

Scope-aware validation before completion.

**Always (any scope):**
- `.ai/docs/README.md` correctly references changed and new files
- content matches the actual code

**Broad scope (new documents, multiple files):**
- full navigation integrity — no orphan docs, no broken links
- placement coherence — domain vs shared

**Narrow scope (augmenting a single file):**
- changed section is consistent with the rest of the file

## Blocker Policy

Stop and ask the user when:
- documentation scope or source of truth cannot be reliably determined
- a conflict exists between code, task artifacts, and existing `.ai/docs`
- the intent behind a docs change is ambiguous after inference

Do not continue on assumptions when the risk of documenting wrong information is high.
Do not take actions the user did not request. Do not guess intent when multiple interpretations exist.
Ask first, act second. A clarifying question is always cheaper than a wrong action.

When asking the user, use `AskUserQuestion` if available on the current platform.

## Completion Criteria

This stage is complete only after the docs validation pass succeeds.

### Within a workflow task

After `/cpdocs` completes, the workflow task is fully complete. Update workflow state accordingly.
Do not automatically clean up branches, worktrees, or execution environment unless explicitly decided.
Post-workflow actions (merge, PR, branch retention, cleanup) should be either already resolved or left as an explicit post-workflow decision.

### Ad hoc docs update (no active workflow task)

After docs validation pass succeeds, the work is complete. Present the user with a summary of what was updated.

No stage can be marked `done` without fresh verification evidence. No workflow status can become `done` without confirmation that all mandatory stages passed relevant checks.
