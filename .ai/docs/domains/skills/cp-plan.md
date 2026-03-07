# cp-plan

## Purpose

Написание плана реализации из утверждённого дизайна. Создаёт структурированный план, готовый для валидации `/cp-plan-review`.

## When to read

- Написание плана реализации после утверждения дизайна
- Понимание формата plan.md и batch files
- Настройка granularity для разных масштабов задач
- Работа с rules pre-check

## Scope

Покрывает написание плана из design.md до handoff к plan review. Не покрывает исследование и дизайн (→ cp-idea) и валидацию плана (→ cp-plan-review).

## Related docs

- [cp-idea](cp-idea.md) — предыдущий шаг: research и design
- [cp-plan-review](cp-plan-review.md) — следующий шаг: валидация плана
- [cp-execute](cp-execute.md) — реализация из плана
- [Workflow](../../shared/workflow.md) — позиция в pipeline

---

## Role

**Delivery lead.** Трансформирует утверждённый дизайн в детальный, исполнимый план реализации.

## Stages

### 1. Context Verification

- Загрузка design.md и workflow.md
- Подтверждение, что дизайн утверждён
- Чтение правил проекта

### 2. Plan Writing

- Создание `<task-slug>.plan.md`
- Определение commit strategy
- Для medium/large задач — создание batch files
- Адаптивная granularity по executor tier

### 3. Rules Pre-check

- Проверка плана на соответствие правилам проекта до передачи на review
- Выявление очевидных нарушений заранее

### 4. Commit

- Фиксация plan.md в workflow

### 5. Handoff

- Автоматический handoff к `/cp-plan-review`

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| `design.md` | Workflow task | Да |
| `workflow.md` | Workflow task | Да |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |
| Документация проекта | `.ai/docs/README.md` | Нет (если существует) |

## Outputs

Артефакты создаются в `.ai/tasks/<YYYY-MM-DD-HHMM-task-slug>/`:

| Артефакт | Формат | Описание |
|----------|--------|----------|
| `<slug>.plan.md` | Markdown | Структурированный план реализации |
| Batch files | Markdown | Для medium/large задач — разбивка на группы |

## Key Rules

- **Design должен быть утверждён** перед написанием плана
- **Commit strategy** должна быть определена в плане
- **Granularity** адаптивна по executor tier (subagent capabilities)
- **Rules pre-check** — обязательный шаг перед передачей на review

## Subagents

| Этап | Tier | Назначение |
|------|------|------------|
| Context gathering | default | Research субагенты для сбора контекста |

Модельная политика: [shared model-policy](../../shared/architecture.md#shared-partials-templates_shared).

## Dependencies

- **Requires:** утверждённый design из `/cp-idea`
- **Next:** `/cp-plan-review` (auto-continuation)

## Change Impact

- Изменение формата plan.md влияет на cp-plan-review, cp-plan-fix, cp-execute, cp-resume
- Изменение granularity правил влияет на качество планов для разных масштабов задач
- Изменение rules pre-check влияет на количество findings на этапе review
