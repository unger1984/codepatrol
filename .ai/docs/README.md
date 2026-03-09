# CodePatrol — AI Documentation

## Purpose

AI-facing project documentation for CodePatrol — a skill system that enhances Superpowers workflow with project rules and documentation awareness for Claude Code and Codex CLI.

## When to read

Start here to understand what documentation exists and where to find it.

## Navigation

### Shared (cross-cutting topics)

| Document | Description | When to read |
|----------|-------------|--------------|
| [Architecture](shared/architecture.md) | Template system, build pipeline, platform abstraction | Understanding how skills are built and deployed |

### Domains

| Document | Description | When to read |
|----------|-------------|--------------|
| [Skills Reference](domains/skills-reference.md) | All skills — overview, workflow integration, shared mechanics | Looking up how skills connect or finding the right skill |
| [Review System](domains/review-system.md) | Code review passes, specialized reviewers, report format, fix tracking | Working with code review or fixing findings |

### Skill Details (domains/skills/)

| Skill | Description | When to read |
|-------|-------------|--------------|
| [using-codepatrol](domains/skills/using-codepatrol.md) | Enhancements for brainstorming and writing-plans | Understanding how project awareness is injected |
| [cp-review](domains/skills/cp-review.md) | Two-pass code review | Running review, reviewer dimensions |
| [cp-fix](domains/skills/cp-fix.md) | Code review findings fix | Fixing code issues, fix agent contract |

## Conventions

- Format: Markdown + Mermaid diagrams
- Language: follows project language rules (Russian for comments, English for internals)
- Scope: stable project knowledge only — no session-specific data
