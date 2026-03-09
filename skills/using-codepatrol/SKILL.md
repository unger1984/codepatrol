---
name: using-codepatrol
description: Use when starting any conversation - enhances brainstorming and writing-plans with project awareness, routes review and fix tasks to CodePatrol skills
---

# CodePatrol — Project-Aware Enhancements

CodePatrol enhances the standard superpowers workflow (brainstorming → writing-plans → executing-plans) with project rules and documentation awareness. It also provides specialized code review and fix skills.

## Skill Routing

| Task type | Skill | Notes |
|-----------|-------|-------|
| New task, idea, feature, or change | brainstorming (superpowers) | Enhanced — see below |
| Write implementation plan | writing-plans (superpowers) | Enhanced — see below |
| Implement from a plan | executing-plans / subagent-driven-development (superpowers) | As-is |
| Code review | `/cp-review` | CodePatrol skill |
| Fix code review findings | `/cp-fix` | CodePatrol skill |
| Create or update project documentation | `/cp-docs` | CodePatrol skill |

## Short Aliases

| User types | Resolve to |
|------------|-----------|
| `/review` | `/cp-review` |
| `/fix` | `/cp-fix` |
| `/docs` | `/cp-docs` |

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

### At "Explore project context" step

Read project-specific context before asking clarifying questions:

1. **Project rules** — ``.claude/rules/*.md` and `CLAUDE.md``
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

### Save design

Save the approved design to `.ai/tasks/YYYY-MM-DD-HHMM-slug/design.md` instead of `docs/plans/`.

The task folder is created on demand — only when saving the first artifact (design or plan). Before generating the folder name, run `date +%H%M` to get the current time. Use the real output. Never hardcode or guess the time. Use `mkdir -p` to create the directory (idempotent — do not check existence separately or ask permission).

### Handoff to writing-plans

After the design is saved, invoke `superpowers:writing-plans` as usual. The enhancements below will apply automatically.

---

## Enhancement: writing-plans

When `superpowers:writing-plans` is invoked, the following enhancements are mandatory and must be applied **in addition to** the standard writing-plans flow.

### Before writing the plan

Read project-specific context:

1. **Project rules** — ``.claude/rules/*.md` and `CLAUDE.md``
2. **Project documentation** — if `.ai/docs/README.md` exists, read it and follow links to docs relevant to the task. This reveals architecture details, conventions, and constraints not captured in rules. It also shows what documentation will need updating after implementation.
3. **Design file** — the approved design from `.ai/tasks/` for the current task

### Include .ai/docs update step

If `.ai/docs/` exists and the task changes architecture, APIs, data structures, or conventions documented there, include an explicit step in the plan to update the affected documentation. Reference the specific docs that need changes and what should change.

If `.ai/docs/` does not exist and the user chose "add a documentation step to the plan" during brainstorming, include a final step to initialize project documentation via `/cp-docs`.

### Self-check after writing

After the plan is written, review it against:
- project rules — no step should violate a known rule or convention
- project documentation — no step should contradict documented architecture
- design file — all design decisions should be reflected in the plan

If conflicts are found, fix them before presenting the plan to the user.

### Save plan

Save the plan to the same task folder as the design. If the design was saved in the current session, reuse its folder path. If the design path is unknown, search `.ai/tasks/` for the most recent `design.md` without a `plan.md` and save alongside it. If no design exists, create a new task folder with `mkdir -p` using the current timestamp.

### Execution handoff

After the plan is saved, follow the standard writing-plans execution handoff (offer subagent-driven or parallel session). Do NOT automatically invoke review after execution — the user decides when to review.

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
When asking the user, use `AskUserQuestion` if available on the current platform.

## Anti-patterns

Do NOT:
- **Invoke multiple skills simultaneously without explicit user request** — route to one skill at a time
- **Skip enhancements when invoking brainstorming or writing-plans** — enhancements are mandatory when CodePatrol is active
- **Auto-invoke execution or review after planning** — the user decides when to proceed to the next stage

## Completion Criteria

This skill is complete when the target skill or enhanced workflow has been identified and invoked. If the skill acts as a router, completion is the successful handoff to the target skill.
