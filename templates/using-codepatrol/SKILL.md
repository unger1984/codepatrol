---
name: using-codepatrol
description: Use when starting any conversation - establishes that CodePatrol workflow skills take priority over generic skills for planning, design, implementation, review, and documentation
---

# CodePatrol Skill Priority

When CodePatrol skills are available, they take priority over generic skills (brainstorming, writing-plans, executing-plans, requesting-code-review, etc.) for the following tasks:

| Task type | Use CodePatrol skill | Instead of generic skill |
|-----------|---------------------|--------------------------|
| New task, idea, feature, or change | `/cpatrol` | brainstorming, writing-plans |
| Implement from a plan | `/cpexecute` | executing-plans, subagent-driven-development |
| Code review | `/cpreview` | requesting-code-review |
| Create or update documentation | `/cpdocs` | — |
| Resume unfinished work | `/cpresume` | — |
| Review a plan | `/cpplanreview` | — |
| Fix code review findings | `/cpfix` | — |
| Fix plan review findings | `/cpplanfix` | — |
| Improve project rules | `/cprules` | — |

## The Rule

Before invoking a generic process skill (brainstorming, writing-plans, executing-plans, debugging, requesting-code-review), check if a CodePatrol skill covers the same task. If it does, use the CodePatrol skill.

Generic skills remain available for tasks that no CodePatrol skill covers (e.g., TDD, systematic debugging, git worktrees, keybindings).

## When the user says...

- "let's plan/design/build/add/create X" → `/cpatrol`
- "implement/execute the plan" → `/cpexecute`
- "review the code/changes" → `/cpreview`
- "add/update/write docs/documentation" → `/cpdocs`
- "continue/resume where we left off" → `/cpresume`
