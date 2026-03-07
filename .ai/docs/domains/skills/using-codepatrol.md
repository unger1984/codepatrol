# using-codepatrol

## Purpose

Устанавливает приоритет скиллов CodePatrol над генерическими аналогами. При получении задачи агент сначала проверяет, есть ли подходящий скилл CodePatrol, и использует его вместо стандартного.

## When to read

- Понимание маршрутизации задач к скиллам
- Добавление нового скилла в систему приоритизации
- Отладка ситуаций, когда вызывается не тот скилл

## Scope

Только маппинг intent-to-skill. Не описывает поведение самих скиллов.

## Related docs

- [Skills Reference](../skills-reference.md) — обзор всех скиллов
- [Workflow](../../shared/workflow.md) — порядок выполнения скиллов

---

## Role

Маршрутизатор задач. Не выполняет никакой работы сам — только перенаправляет на правильный скилл.

## Routing Table

| Intent пользователя | CodePatrol скилл | Заменяет генерический |
|---------------------|------------------|-----------------------|
| Новая задача / идея / дизайн | `/cp-idea` | brainstorming |
| Написание плана реализации | `/cp-plan` | writing-plans |
| Реализация по плану | `/cp-execute` | executing-plans |
| Code review | `/cp-review` | requesting-code-review |
| Документация | `/cp-docs` | — |
| Продолжить работу | `/cp-resume` | — |
| Проверка плана | `/cp-plan-review` | — |
| Исправление плана | `/cp-plan-fix` | — |
| Исправление кода | `/cp-fix` | — |
| Улучшение правил | `/cp-rules` | — |

## Trigger Examples

- "let's plan/design/build X" → `/cp-idea`
- "implement the plan" → `/cp-execute`
- "review the code" → `/cp-review`
- "update docs" → `/cp-docs`
- "continue yesterday's work" → `/cp-resume`

## Key Rule

Перед вызовом любого генерического скилла (brainstorming, writing-plans, executing-plans, requesting-code-review) — проверить таблицу маршрутизации. Если есть CodePatrol-аналог, использовать его.

## Inputs / Outputs

- **Input:** сообщение пользователя (intent)
- **Output:** вызов соответствующего скилла CodePatrol

## Dependencies

Нет зависимостей. Это entry-point скилл, загружаемый при старте сессии.

## Subagents

Не использует субагентов.

## Change Impact

- Добавление нового скилла CodePatrol требует обновления routing table
- Изменение имени скилла требует обновления маппинга
