# Skills Reference

## Purpose

Reference for all CodePatrol skills — purpose, inputs/outputs, stages, and inter-skill dependencies.

## When to read

- Looking up what a specific skill does
- Understanding skill inputs and outputs
- Checking how skills connect to each other
- Adding or modifying a skill

## Scope

All skills in `templates/`. For build mechanics see [Architecture](../shared/architecture.md). For workflow overview see [Workflow](../shared/workflow.md).

## Related docs

- [Workflow](../shared/workflow.md) — pipeline and artifact storage
- [Review System](review-system.md) — detailed review mechanics
- [Architecture](../shared/architecture.md) — template system

---

## Skills Overview

| Skill | Purpose | Detailed doc |
|-------|---------|-------------|
| [using-codepatrol](skills/using-codepatrol.md) | Маршрутизация задач к скиллам CodePatrol вместо генерических | [details](skills/using-codepatrol.md) |
| [cp-idea](skills/cp-idea.md) | Research и design для новой задачи (entry point) | [details](skills/cp-idea.md) |
| [cp-plan](skills/cp-plan.md) | Написание плана реализации из утверждённого дизайна | [details](skills/cp-plan.md) |
| [cp-plan-review](skills/cp-plan-review.md) | Валидация плана перед реализацией | [details](skills/cp-plan-review.md) |
| [cp-plan-fix](skills/cp-plan-fix.md) | Исправление findings из plan review | [details](skills/cp-plan-fix.md) |
| [cp-execute](skills/cp-execute.md) | Реализация кода из утверждённого плана | [details](skills/cp-execute.md) |
| [cp-review](skills/cp-review.md) | Двухпроходный code review (compliance + quality) | [details](skills/cp-review.md) |
| [cp-fix](skills/cp-fix.md) | Исправление findings из code review | [details](skills/cp-fix.md) |
| [cp-docs](skills/cp-docs.md) | Создание/обновление AI-facing документации | [details](skills/cp-docs.md) |
| [cp-resume](skills/cp-resume.md) | Восстановление прерванной работы | [details](skills/cp-resume.md) |
| [cp-rules](skills/cp-rules.md) | Улучшение правил проекта из паттернов | [details](skills/cp-rules.md) |

## Workflow Pipeline

```
/cp-idea → /cp-plan → /cp-plan-review → /cp-plan-fix (if findings) → /cp-execute → /cp-review → /cp-fix (if findings) → /cp-docs → /cp-rules (optional)
```

Cross-cutting: `/cp-resume` — resume с любого этапа. `/using-codepatrol` — routing при старте.

## Shared Mechanics

| Механика | Где используется | Описание |
|----------|------------------|----------|
| Progress tracking | Все скиллы | Mandatory — progress items до старта работы |
| Incremental report mutation | cp-plan-fix, cp-fix | Обновление отчёта после каждого finding (не batch) |
| Ad hoc save gate | cp-plan-review, cp-review, cp-plan-fix, cp-fix | Файл не сохраняется без explicit user approval |
| Model policy | cp-idea, cp-plan, cp-plan-review, cp-execute, cp-review, cp-docs | Subagent tiers: fast/default/powerful + ceiling rule |
| Bounded revalidation | cp-plan-fix, cp-fix | Revalidation только изменённых секций |
| Blocker policy | Все скиллы | Stop и ask при conflicts, ambiguity, verification failure |

## Inter-Skill Dependencies

```mermaid
flowchart TD
    UC[using-codepatrol] -.->|routes to| CP[cp-idea]
    CP -->|design.md| PL[cp-plan]
    PL -->|plan.md| PPR[cp-plan-review]
    PPR -->|findings| PPF[cp-plan-fix]
    PPF -->|re-check| PPR
    PPR -->|approved| EX[cp-execute]
    EX -->|code| CR[cp-review]
    CR -->|findings| CF[cp-fix]
    CF -->|re-check| CR
    CR -->|approved| CD[cp-docs]
    CD --> CRL[cp-rules]
    RES[cp-resume] -.->|any stage| CP
    RES -.-> PL
    RES -.-> PPR
    RES -.-> EX
    RES -.-> CR
    RES -.-> CD
```

## Change Impact

- Adding a new skill: create template dir, add SKILL.md with frontmatter, rebuild, update using-codepatrol mapping, add doc in `skills/`
- Modifying skill stages: update the skill doc + workflow doc + cp-resume detection logic
- Changing report format: update cp-fix/cp-plan-fix parsing + cp-resume detection + cp-rules analysis
