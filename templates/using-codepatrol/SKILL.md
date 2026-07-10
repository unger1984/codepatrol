---
name: using-codepatrol
description: MUST invoke BEFORE superpowers:brainstorming or superpowers:writing-plans — required when building features, designing systems, planning changes, creating functionality, adding components, or any creative/implementation task. Also routes review/fix/docs requests to CodePatrol skills. Adds mandatory project rules and documentation context.
---

# CodePatrol — Project-Aware Enhancements

CodePatrol enhances the standard superpowers workflow (brainstorming → writing-plans → executing-plans) with project rules and documentation awareness. It also provides specialized code review and fix skills.

**CRITICAL — Enhancement Gate:** Before invoking `superpowers:brainstorming` or `superpowers:writing-plans`, you MUST ensure this skill's enhancement sections are loaded in context. If you are unsure whether they are — invoke `using-codepatrol` via the Skill tool first. Never invoke brainstorming or writing-plans without the enhancements below being active. This applies regardless of how the invocation was triggered (user request, slash command, or handoff from another skill).

## Skill Routing

| Task type | Skill | Notes |
|-----------|-------|-------|
| New task, idea, feature, or change | brainstorming (superpowers) | Enhanced — see below |
| Write implementation plan | writing-plans (superpowers) | Enhanced — see below |
| Implement from a plan | executing-plans / subagent-driven-development (superpowers) | As-is |
| Code review | `/cp-review` | CodePatrol skill |
| Fix code review findings | `/cp-fix` | CodePatrol skill |
| Create or update project documentation | `/cp-docs` | CodePatrol skill |

{{@platform-include:aliases}}

## When the user says...

- "let's plan/design/build/add/create X" / "brainstorm" / "I have an idea" → brainstorming (with enhancements)
- "write the plan" / "create implementation plan" → writing-plans (with enhancements)
- "implement/execute the plan" / "let's build it" → executing-plans or subagent-driven-development
- "review the code/changes" / "check my code" → `/cp-review`
- "fix the findings" / "fix review issues" → `/cp-fix`
- "add/update/write docs/documentation" → `/cp-docs`

---

## Enhancement: brainstorming

When `superpowers:brainstorming` is invoked, the following enhancements are mandatory and must be applied **in addition to** the standard brainstorming flow.

The standard flow may include steps CodePatrol does not override — a just-in-time visual companion offer, a spec self-review, and a user-review gate before planning. Leave those intact. The enhancements here only add project-context reads and redirect where the artifact is saved; they do not replace or re-order the standard flow.

### At "Explore project context" step

Read project-specific context before asking clarifying questions:

1. **Project rules** — `{{RULES_SOURCE}}`
2. **Project documentation** — if `.ai/docs/README.md` exists, read it as a navigation hub. Follow links only to docs relevant to the task scope.
3. **Recent commits** — `git log --oneline -20` for recent activity context

If `.ai/docs/` does not exist, ask the user (multiple choice, one question at a time):
- Create project documentation now before designing (invoke `/cp-docs`)
- Add a documentation initialization step to the plan after implementation
- Proceed without project documentation

Recommend the second option for most cases. Remember the user's choice — it affects the writing-plans enhancement.

This context informs all subsequent steps: questions, approaches, and design.

### At "Propose approaches" step

Before presenting approaches, verify each candidate against project rules and conventions discovered during context exploration. If an approach conflicts with a project rule, either discard it or explicitly note the conflict and why the rule should be overridden.

### At "Present design" step

In the design, explicitly reference relevant project rules and constraints that shaped design decisions. The user should see that the design was informed by the project's own conventions, not just general best practices.

### Save design (location override)

Wherever the standard flow would write the design/spec, CodePatrol redirects it to `.ai/tasks/YYYY-MM-DD-HHMM-slug/design.md`. This override applies regardless of the standard flow's default location (as of Superpowers 6.1.x that default is `docs/superpowers/specs/`). Do not also write a copy to the default path — `.ai/tasks/` is the single home for the artifact.

The task folder is created on demand — only when saving the first artifact (design or plan). Before generating the folder name, get the current time by running a shell command: `date +%H%M` (Unix/macOS) or `Get-Date -Format 'HHmm'` (PowerShell/Windows). Use the real output. Never hardcode or guess the time. Save the file using the Write tool — it creates parent directories automatically. Do not use shell commands (`mkdir`, `New-Item`) to create directories.

Whatever the standard flow does with the artifact after saving (its spec self-review, committing it) still applies — it just operates on the `.ai/tasks/` file.

### Handoff to writing-plans

Do not jump straight to writing-plans after saving. Continue through the standard flow's remaining steps — its spec self-review and the user-review gate — operating on the `.ai/tasks/` design file. The flow itself transitions to `superpowers:writing-plans` once the user approves the spec, and the enhancements below apply automatically at that point.

---

## Enhancement: writing-plans

When `superpowers:writing-plans` is invoked, the following enhancements are mandatory and must be applied **in addition to** the standard writing-plans flow.

### Before writing the plan

Read project-specific context:

1. **Project rules** — `{{RULES_SOURCE}}`
2. **Project documentation** — if `.ai/docs/README.md` exists, read it and follow links to docs relevant to the task. This reveals architecture details, conventions, and constraints not captured in rules. It also shows what documentation will need updating after implementation.
3. **Design file** — the approved design from `.ai/tasks/` for the current task

### Include .ai/docs update step

If `.ai/docs/` exists and the task changes architecture, APIs, data structures, or conventions documented there, include an explicit step in the plan to update the affected documentation. Reference the specific docs that need changes and what should change.

If `.ai/docs/` does not exist and the user chose "add a documentation step to the plan" during brainstorming, include a final step to initialize project documentation via `/cp-docs`.

### Project self-check after writing

The standard flow already runs its own generic self-review (spec coverage, placeholder scan, type consistency). This is the CodePatrol layer on top of it — a project-specific pass, not a replacement. After the plan is written, additionally review it against:
- project rules — no step should violate a known rule or convention
- project documentation — no step should contradict documented architecture
- design file — all design decisions should be reflected in the plan

If conflicts are found, fix them before presenting the plan to the user.

### Save plan (location override)

Redirect the plan to the same `.ai/tasks/` task folder as the design, regardless of the standard flow's default location (as of Superpowers 6.1.x that default is `docs/superpowers/plans/`). If the design was saved in the current session, reuse its folder path. If the design path is unknown, search `.ai/tasks/` for the most recent `design.md` without a `plan.md` and save alongside it. If no design exists, save the plan to a new task folder with the current timestamp — the Write tool creates parent directories automatically.

### Execution handoff

After the plan is saved, follow the standard writing-plans execution handoff — it offers Subagent-Driven execution (`superpowers:subagent-driven-development`) or Inline Execution (`superpowers:executing-plans`). Do NOT automatically invoke review after execution — the user decides when to review.

---

## Task Folder Structure

All task artifacts are stored in `.ai/tasks/`. Task folders are created on demand when the first artifact is saved, not upfront.

```
.ai/tasks/YYYY-MM-DD-HHMM-slug/
├── design.md    — approved design
├── plan.md      — implementation plan
└── review.md    — code review report (created by /cp-review)
```

The slug should be short and descriptive, derived from the task subject.

## Blocker Policy

Stop and ask the user when:
- the user's request does not clearly map to any skill or enhancement
- multiple skills could apply and the choice affects the outcome

Do not guess which skill to invoke. Present concrete options and let the user choose.
When asking the user, use `{{ASK_USER}}` if available on the current platform.

## Anti-patterns

Do NOT:
- **Invoke multiple skills simultaneously without explicit user request** — route to one skill at a time
- **Skip enhancements when invoking brainstorming or writing-plans** — enhancements are mandatory when CodePatrol is active
- **Auto-invoke execution or review after planning** — the user decides when to proceed to the next stage

## Completion Criteria

This skill is complete when the target skill or enhanced workflow has been identified and invoked. If the skill acts as a router, completion is the successful handoff to the target skill.
