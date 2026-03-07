# cp-rules

## Purpose

Анализ паттернов из завершённых задач и review-отчётов для улучшения правил проекта.

## When to read

- Улучшение правил проекта после серии задач
- Понимание двухфазного workflow (propose → apply)
- Анализ recurring patterns из review reports

## Scope

Покрывает анализ паттернов и применение rule changes. Не покрывает сам review (→ cp-review) или fix (→ cp-fix).

## Related docs

- [cp-docs](cp-docs.md) — предыдущий шаг в workflow
- [cp-review](cp-review.md) — источник review reports
- [Workflow](../../shared/workflow.md) — позиция в pipeline

---

## Role

**Rules improvement advisor.** Ищет повторяющиеся паттерны, предлагает изменения правил, применяет только одобренные.

## Analysis Targets

Что анализируется:
- Completed workflow artifacts
- Review reports (findings, fixes)
- Repeated fix patterns
- Existing rule files

Что ищется:
- **Missing rules** — проблемы, которые правила не предотвратили
- **Weak rules** — правила, которые не работают эффективно
- **Outdated rules** — правила, не соответствующие текущей кодовой базе

## Two-Phase Workflow

### Phase 1 — Analyze and Propose (no file changes)

Для каждого finding:

| Поле | Описание |
|------|----------|
| Recurring pattern | Паттерн, встречающийся в нескольких задачах |
| Recommended rule change | Конкретное изменение правила |
| Rationale | Почему это изменение важно |
| Expected benefit | Ожидаемый эффект |

Всё представляется в conversation. Файлы не меняются.

### Phase 2 — Apply (user-approved only)

- Применить **только** одобренный пользователем subset
- Prefer updating existing rule file over creating new
- Summarize applied changes

## Key Rules

- **Никогда** не модифицировать файлы без explicit user approval
- Не создавать rule churn из one-off issues (только recurring patterns)
- Объяснять почему каждое предложенное правило worth adding/changing
- Предпочитать обновление существующего файла правил созданию нового

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| Workflow artifacts | `.ai/tasks/` | Нет (но рекомендуется) |
| Review reports | `.ai/tasks/` / `.ai/reports/` | Нет |
| Rule files | CLAUDE.md / AGENTS.md / `.claude/rules/` | Да |
| `.ai/docs/README.md` | Existing docs | Нет |

## Outputs

- Предложения по изменению правил (в conversation)
- Применённые изменения в rule files (после approval)
- Summary применённых изменений

## Subagents

Не использует субагентов напрямую.

## Dependencies

- **Requires:** завершённые workflow tasks и/или review reports (рекомендуется)
- **Next:** ничего (финальный опциональный шаг)

## Change Impact

- Изменение формата proposals влияет на UX
- Изменение analysis targets расширяет/сужает coverage
- Правила, созданные cp-rules, влияют на все последующие задачи
