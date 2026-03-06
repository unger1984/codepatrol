# cpatrol

## Purpose

Entry point для новой задачи. Проводит исследование, проектирование решения и создание плана реализации.

## When to read

- Начало работы над новой задачей
- Понимание формата артефактов (workflow.md, design.md, plan.md)
- Настройка глубины workflow для разных масштабов задач
- Отладка проблем с research-субагентами

## Scope

Покрывает весь путь от идеи до готового плана. Не покрывает реализацию (→ cpexecute) и review (→ cpreview).

## Related docs

- [cpplanreview](cpplanreview.md) — следующий шаг: валидация плана
- [cpexecute](cpexecute.md) — реализация из плана
- [Workflow](../../shared/workflow.md) — позиция в pipeline

---

## Role

**Senior software architect + delivery lead.** Исследует проблему, предлагает варианты, итерирует с пользователем, фиксирует дизайн и план.

## Stages

Все этапы обязательны для progress tracking.

### 1. Research (субагент, default tier)

Субагент читает `.ai/docs/README.md` (если есть), код проекта, правила и возвращает структурированный summary:
- Key findings
- Confirmed facts
- Assumptions
- Open questions

### 2. Clarification

Формулирует вопросы пользователю на основе research. Не переходит дальше, пока неясности не разрешены.

### 3. Approach Options

Предлагает 2-3 альтернативных подхода с trade-offs. Пользователь выбирает направление.

### 4. Solution Outline

Итеративная проработка выбранного подхода с пользователем до достижения согласия.

### 5. Research Refresh (субагент, default tier)

Целевая перепроверка выбранного подхода — подтверждение, что решение валидно с учётом кодовой базы.

### 6. Design

Создание `<task-slug>.design.md` — утверждённая архитектура. Формат: Markdown + Mermaid.

### 7. Plan

Создание `<task-slug>.plan.md` — детальный план реализации, готовый для `/cpplanreview`. Включает commit strategy.

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| Описание задачи | Пользователь | Да |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |
| Документация проекта | `.ai/docs/README.md` | Нет (если существует) |

## Outputs

Все артефакты создаются в `.ai/tasks/<YYYY-MM-DD-HHMM-task-slug>/`:

| Артефакт | Формат | Описание |
|----------|--------|----------|
| `<slug>.workflow.md` | Markdown (English) | Статус, этапы, решения, история |
| `<slug>.design.md` | Markdown + Mermaid | Утверждённый дизайн |
| `<slug>.plan.md` | Markdown | Структурированный план реализации |

## Key Rules

- **Research обязателен** — нельзя пропустить даже для "простых" задач
- **Классификация сложности** (small/medium/large) определяет глубину workflow
- **Commit strategy** должна быть определена до написания плана
- **mkdir -p** для `.ai/` — idempotent, разрешение не требуется
- Не переходить к дизайну, пока research и обсуждение недостаточны

## Subagents

| Этап | Tier | Назначение |
|------|------|------------|
| Research | default | Чтение docs, кода, правил → summary |
| Research Refresh | default | Перепроверка выбранного подхода |

Модельная политика: [shared model-policy](../../shared/architecture.md#shared-partials-templates_shared).

## Dependencies

- **Requires:** ничего (entry point)
- **Next:** `/cpplanreview`

## Change Impact

- Изменение формата артефактов влияет на все downstream скиллы (cpplanreview, cpexecute, cpresume)
- Изменение этапов требует обновления cpresume (detection logic)
- Изменение research contract влияет на качество всех последующих этапов
