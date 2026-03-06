# cpexecute

## Purpose

Реализация кода из утверждённого плана с checkpoint-верификацией на каждом этапе.

## When to read

- Реализация фичи по плану
- Понимание контракта implementer-субагентов
- Настройка execution strategy и checkpoint reporting
- Работа с handoff к code review

## Scope

Покрывает реализацию из plan.md до handoff к review. Не покрывает планирование (→ cpatrol) и review (→ cpreview).

## Related docs

- [cpatrol](cpatrol.md) — создание плана
- [cpplanreview](cpplanreview.md) + [cpplanfix](cpplanfix.md) — валидация плана
- [cpreview](cpreview.md) — следующий шаг: code review

---

## Role

**Execution orchestrator.** Читает план как execution contract, строит граф выполнения, dispatch-ит работу субагентам, контролирует checkpoints.

## Preconditions

Все должны быть выполнены перед стартом:

- Активная workflow задача
- Утверждённый design state (если создавался)
- Текущий plan file
- Завершённые `/cpplanreview` + `/cpplanfix`
- Bounded revalidation показывает plan ready for execution

## Execution Preflight

1. Загрузить `plan.md`
2. Загрузить workflow decisions из `workflow.md`
3. Прочитать `.ai/docs/README.md` → только релевантные docs
4. Подтвердить safety целевой ветки (не main/master без одобрения)
5. Определить verification команды для каждого сегмента плана

## Execution Strategy

1. Читать план как execution contract (порядок этапов, зависимости)
2. Построить execution graph из stages и steps
3. Определить dependencies и safe parallelization zones
4. Если несколько стратегий возможны → спросить пользователя

## Implementer Subagent Contract

Каждый субагент-имплементатор обязан:

- Следовать правилам проекта, стилю, архитектурным constraints
- Работать только в рамках назначенного scope
- Запустить self-check перед handoff
- Проверить nearest impact от своих изменений
- Запустить lint, tests, checks проекта
- Фиксить obvious problems в своём scope
- Escalate конфликты обратно оркестратору

## Checkpoint Reporting

После каждого stage:
- Что выполнено из плана
- Какая verification запущена и результат
- Что осталось открытым
- Blockers, новые risks

## Handoff to /cpreview

- **Не запускать review автоматически**
- Предложить два пути:
  1. Review сейчас (в текущей сессии)
  2. Review в новой сессии

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| `plan.md` | Workflow task | Да |
| `workflow.md` | Workflow task | Да |
| `design.md` | Workflow task | Нет |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |
| Документация проекта | `.ai/docs/` | Нет |

## Outputs

- Реализованный код согласно плану
- Обновлённый `workflow.md` с отметками о выполненных этапах
- Checkpoint reports в conversation

## Subagents

| Роль | Tier | Назначение |
|------|------|------------|
| Implementer | По сложности задачи | Реализация конкретного stage/step |

Модельная политика: shared model-policy (fast/default/powerful tiers).

## Dependencies

- **Requires:** завершённые `/cpatrol`, `/cpplanreview`, `/cpplanfix`
- **Next:** `/cpreview`

## Change Impact

- Изменение implementer contract влияет на качество реализации
- Изменение checkpoint reporting влияет на observability
- Изменение handoff логики влияет на переход к review
