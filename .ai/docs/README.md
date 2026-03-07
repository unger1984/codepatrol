# CodePatrol — AI Documentation

## Purpose

AI-facing project documentation for CodePatrol — a workflow-first skill system for Claude Code and Codex CLI.

## When to read

Start here to understand what documentation exists and where to find it.

## Navigation

### Shared (cross-cutting topics)

| Document | Description | When to read |
|----------|-------------|--------------|
| [Architecture](shared/architecture.md) | Template system, build pipeline, platform abstraction | Understanding how skills are built and deployed |
| [Workflow](shared/workflow.md) | Skill lifecycle, stages, artifact storage, resume model | Understanding the full task workflow from planning to completion |

### Domains

| Document | Description | When to read |
|----------|-------------|--------------|
| [Skills Reference](domains/skills-reference.md) | All skills — overview, pipeline, shared mechanics | Looking up how skills connect or finding the right skill |
| [Review System](domains/review-system.md) | Code review passes, specialized reviewers, report format, fix tracking | Working with code review or fixing findings |

### Skill Details (domains/skills/)

Детальная документация каждого скилла — role, stages, inputs/outputs, rules, dependencies.

| Skill | Description | When to read |
|-------|-------------|--------------|
| [using-codepatrol](domains/skills/using-codepatrol.md) | Task routing to CodePatrol skills | Understanding skill priority and routing |
| [cp-idea](domains/skills/cp-idea.md) | Research and design | Starting a new task, understanding artifacts |
| [cp-plan](domains/skills/cp-plan.md) | Implementation planning from approved design | Writing plan from design |
| [cp-plan-review](domains/skills/cp-plan-review.md) | Plan validation | Reviewing plan before execution |
| [cp-plan-fix](domains/skills/cp-plan-fix.md) | Plan findings fix | Fixing plan review issues |
| [cp-execute](domains/skills/cp-execute.md) | Code implementation from plan | Implementing features, subagent contracts |
| [cp-review](domains/skills/cp-review.md) | Two-pass code review | Running review, reviewer dimensions |
| [cp-fix](domains/skills/cp-fix.md) | Code review findings fix | Fixing code issues, fix agent contract |
| [cp-docs](domains/skills/cp-docs.md) | AI-facing documentation | Creating or updating docs |
| [cp-resume](domains/skills/cp-resume.md) | Session recovery | Resuming interrupted work |
| [cp-rules](domains/skills/cp-rules.md) | Rules evolution | Improving project rules from patterns |

## Conventions

- Format: Markdown + Mermaid diagrams
- Language: follows project language rules (Russian for comments, English for internals)
- Scope: stable project knowledge only — no session-specific data
