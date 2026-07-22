---
name: using-codepatrol
description: MUST invoke BEFORE superpowers:brainstorming or superpowers:writing-plans whenever a brainstorm, design, or plan workflow for a feature or change is about to start. Loads mandatory project-rules and documentation enhancements. Not for direct well-scoped edits, localized fixes, execution, reviews, investigations, or documentation tasks.
---

# CodePatrol — Project-Aware Enhancements

CodePatrol enhances the standard Superpowers planning workflow with project rules, relevant documentation,
and centralized task artifacts. Superpowers remains the primary workflow: these enhancements do not replace
or reorder its steps.

**CRITICAL — Enhancement Gate:** Before invoking `superpowers:brainstorming` or
`superpowers:writing-plans`, you MUST ensure this skill's enhancement sections are loaded in context. If you
are unsure whether they are, invoke `using-codepatrol` first. Never invoke brainstorming or writing-plans
without the enhancements below being active.

## Short Aliases

| User types | Resolve to |
|------------|-----------|
| `/review` | `/cp-review` |
| `/fix` | `/cp-fix` |
| `/docs` | `/cp-docs` |

## Related CodePatrol Skills

Use `/cp-review`, `/cp-fix`, and `/cp-docs` only for their explicit workflows. They do not start or replace
Superpowers planning.

## Planning Threshold

Start the Superpowers `brainstorming → writing-plans` flow only when:

1. the user explicitly asks to brainstorm, design, or write an implementation plan; or
2. before editing there is a decision requiring user approval: viable approaches have materially different
   cost or risk, or the requirement cannot be resolved from project rules, documentation, and code.

Do **not** start planning solely because the user says “add”, “build”, “create”, “change”, or “fix”. Directly
execute work with a clear scope, including:

- one-file or other localized changes;
- bug fixes with a known cause;
- mechanical refactors;
- review, documentation, or investigation tasks;
- execution of an approved plan.

When uncertain, prefer direct implementation. Start planning later only if a real design decision emerges.

---

## Enhancement: brainstorming

When `superpowers:brainstorming` is invoked, apply these requirements in addition to the standard flow.

### Explore project context

Before asking clarifying questions:

1. **Project rules** — ``.claude/rules/*.md` and `CLAUDE.md``
2. **Project documentation** — if `.ai/docs/README.md` exists, read it as a navigation hub and follow only
   links relevant to the task scope.

If `.ai/docs/` does not exist, continue without it. Do not ask the user to initialize documentation or add a
documentation task solely because it is absent.

### Propose approaches

Verify each proposed approach against the discovered project rules and conventions. Discard conflicting
approaches or explicitly explain why a rule must be overridden.

### Present design

Reference the relevant project rules and constraints that shaped the design.

### CodePatrol design self-check

Before the standard Superpowers user-review gate, run independent read-only checks for the design's artifact
integrity and its compliance with project rules, documentation, and explicit user requirements. Normalize the
findings, then correct them before presenting the design unless a correction changes a material design choice.
Present material choices to the user instead of silently choosing one.

- Dispatch planning checks as separate read-only Agent calls. For a design: artifact integrity → fast; rules, docs, and requirement compliance → powerful. For a plan: artifact integrity → fast; completeness, dependencies, scope, and verification → default; rules/docs/design compliance → powerful.
- For every powerful compliance self-check, pass only the minimal prepared context: current artifact, applicable rule and documentation excerpts, and explicit requirements. It must not perform broad discovery for unrelated documents.
- Dispatch fixes one finding at a time with the configured tier: simple artifact repair → fast; standard plan repair → default; complex design or compliance repair → powerful. Keep the artifact's user-review gate and do not silently change material design decisions.

### Save design

Save the design only to `.ai/tasks/YYYY-MM-DD-HHMM-slug/design.md`. This location overrides the standard
Superpowers spec path; never write a second copy to a default Superpowers directory.

Create the task folder only when saving the first artifact. Before generating its timestamp, run `date +%H%M`
on Unix/macOS or `Get-Date -Format 'HHmm'` on PowerShell. Save with the Write tool; do not create directories
through shell commands.

---

## Enhancement: writing-plans

When `superpowers:writing-plans` is invoked, apply these requirements in addition to the standard flow.

### Before writing the plan

Read:

1. **Project rules** — ``.claude/rules/*.md` and `CLAUDE.md``
2. **Project documentation** — if `.ai/docs/README.md` exists, follow only relevant linked docs.
3. **Approved design** — the design for the current task, if one exists.

### Include documentation updates

If existing `.ai/docs` documents architecture, APIs, data structures, or conventions changed by the task,
include an explicit update step naming the affected document and required update. Do not add an initialization
step when `.ai/docs` is absent.

### CodePatrol plan self-check

After the standard Superpowers plan review, run independent read-only checks for:

- artifact integrity, links, and placeholders;
- plan completeness, dependency order, verification, and scope;
- compliance with project rules, relevant documentation, and the approved design.

Normalize findings and correct them before presenting the plan. A correction that changes an approved design
decision is a blocker: present the conflict to the user rather than silently changing the design.

- Dispatch planning checks as separate read-only Agent calls. For a design: artifact integrity → fast; rules, docs, and requirement compliance → powerful. For a plan: artifact integrity → fast; completeness, dependencies, scope, and verification → default; rules/docs/design compliance → powerful.
- For every powerful compliance self-check, pass only the minimal prepared context: current artifact, applicable rule and documentation excerpts, and explicit requirements. It must not perform broad discovery for unrelated documents.
- Dispatch fixes one finding at a time with the configured tier: simple artifact repair → fast; standard plan repair → default; complex design or compliance repair → powerful. Keep the artifact's user-review gate and do not silently change material design decisions.

### Save plan

Save the plan only to `.ai/tasks/YYYY-MM-DD-HHMM-slug/plan.md`, beside the current task's design. Never write
a second copy to a default Superpowers plan directory.

A design is current only when it was approved in this session or the user explicitly supplied its path. If the
user asks for a plan based on an existing design but its path is not known, ask for that path. Otherwise create
a new task folder with the current timestamp. Never search `.ai/tasks/` for the most recent design without a
plan.

---

## Task Folder Structure

```
.ai/tasks/YYYY-MM-DD-HHMM-slug/
├── design.md    — approved design
├── plan.md      — implementation plan
└── review.md    — code review report, created by /cp-review when applicable
```

The slug is short, descriptive, and derived from the task subject.

## Anti-patterns

Do NOT:

- activate this skill for direct implementation that does not use brainstorming or writing-plans;
- skip these enhancements once brainstorming or writing-plans is invoked;
- create duplicate design or plan artifacts in default Superpowers directories;
- infer a task design by searching for the most recent unmatched design;
- automatically invoke execution or review after planning.

## Completion Criteria

This skill is complete when the enhanced Superpowers workflow has been invoked with these requirements active
and any design or plan artifact has been saved in its single `.ai/tasks/` location.
