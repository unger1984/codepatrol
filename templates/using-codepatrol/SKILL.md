---
name: using-codepatrol
description: Use when starting any conversation - establishes that CodePatrol workflow skills take priority over generic skills for planning, design, implementation, review, and documentation
---

# CodePatrol Skill Priority

When CodePatrol skills are available, they take priority over generic skills (brainstorming, writing-plans, executing-plans, requesting-code-review, etc.) for the following tasks:

| Task type | Use CodePatrol skill | Instead of generic skill |
|-----------|---------------------|--------------------------|
| New task, idea, feature, or change | `/cp-idea` | brainstorming |
| Write implementation plan from design | `/cp-plan` | writing-plans |
| Implement from a plan | `/cp-execute` | executing-plans, subagent-driven-development |
| Code review | `/cp-review` | requesting-code-review |
| Create or update documentation | `/cp-docs` | — |
| Resume unfinished work | `/cp-resume` | — |
| Review a plan | `/cp-plan-review` | — |
| Fix code review findings | `/cp-fix` | — |
| Fix plan review findings | `/cp-plan-fix` | — |
| Improve project rules | `/cp-rules` | — |

## The Rule

Before invoking a generic process skill (brainstorming, writing-plans, executing-plans, debugging, requesting-code-review), check if a CodePatrol skill covers the same task. If it does, use the CodePatrol skill.

Generic skills remain available for tasks that no CodePatrol skill covers (e.g., TDD, systematic debugging, git worktrees, keybindings).

## Short Aliases

Users may invoke commands without the `cp-` prefix. Resolve these to the corresponding CodePatrol skill:

| User types | Resolve to |
|------------|-----------|
| `/idea`, `/design`, `/brainstorm` | `/cp-idea` |
| `/plan` | `/cp-plan` |
| `/execute`, `/implement`, `/run` | `/cp-execute` |
| `/review` | `/cp-review` |
| `/fix` | `/cp-fix` |
| `/plan-review` | `/cp-plan-review` |
| `/plan-fix` | `/cp-plan-fix` |
| `/docs` | `/cp-docs` |
| `/resume` | `/cp-resume` |
| `/rules` | `/cp-rules` |

If a short alias conflicts with another installed skill, prefer the CodePatrol skill.

## When the user says...

- "let's plan/design/build/add/create X" → `/cp-idea`
- "brainstorm" / "let's think about" / "I have an idea" → `/cp-idea`
- "write the plan" / "create implementation plan" → `/cp-plan`
- "implement/execute the plan" / "let's build it" → `/cp-execute`
- "review the code/changes" / "check my code" → `/cp-review`
- "fix the findings" / "fix review issues" → `/cp-fix`
- "add/update/write docs/documentation" → `/cp-docs`
- "continue/resume where we left off" → `/cp-resume`
- "let's work on rules" / "improve/add/update rules" / "add linting rules" → `/cp-rules`
