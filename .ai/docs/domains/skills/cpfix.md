# cpfix

## Purpose

Обработка open findings из отчёта `/cpreview` — исправление кода, обновление тестов, мутация отчёта.

## When to read

- Исправление кода после code review
- Понимание fix policy и processing order
- Работа с incremental report mutation
- Понимание контракта fix-agent субагента

## Scope

Покрывает исправление code review findings. Не покрывает сам review (→ cpreview) и исправление плана (→ cpplanfix).

## Related docs

- [cpreview](cpreview.md) — источник findings
- [cpdocs](cpdocs.md) — следующий шаг после исправления
- [cpplanfix](cpplanfix.md) — аналогичная механика для plan findings
- [Review System](../review-system.md) — подробности формата и tracking

---

## Role

**Implementation fixer.** Разбирает findings по приоритету, применяет fix к коду, обновляет отчёт.

## Report Source

Отчёт загружается из (в порядке приоритета):
1. Explicit path (аргумент пользователя)
2. Последний review report из workflow task
3. Current conversation context (если review только что прошёл)

## Processing Order

1. **Compliance findings** — первый приоритет (design/plan/rules violations)
2. **Quality findings** — второй приоритет (architecture, security, testing, conventions)

Не переходить к quality, пока открыты compliance findings.

## Fix Policy

Определяется перед стартом:

| Параметр | Варианты |
|----------|----------|
| Severity scope | только critical / critical + important / все |
| Processing style | manual per item / auto simple (ask for complex) / custom |

Если policy неясна → спросить пользователя.

### Auto-fix vs Ask-user

- **Auto-fix:** разрешение локальное, intent ясен, нет trade-offs
- **Ask-user:** несколько валидных вариантов, scope/architecture impact, конфликт с constraints

## Incremental Report Mutation (mandatory)

После каждого finding (не в batch!):

1. Apply fix или decide skip/defer
2. Run bounded revalidation
3. **Немедленно обновить файл отчёта** (если существует):
   - `Status: open` → `resolved | skipped | deferred`
   - `Resolved via: <file:line or "skipped">`
   - `Resolution notes: <explanation>`
4. Mark progress item as completed

Если файл не существует (context-only) → записать в conversation memory.

## Fix Agent (субагент)

Для субагентных fix-ов, fix agent получает:
- Issue title, severity, finding type
- File path, problem description
- Chosen fix approach
- Project rules

Контракт fix agent:
1. Read target file + smallest relevant context
2. Apply fix exactly, adapt only to fit real code
3. Add short why-comment для non-trivial changes
4. Не добавлять comments для mechanical renames, formatting, obvious changes
5. Update tests если изменились public interfaces
6. Run verification (smallest relevant → broader)
7. **Не делать commit**
8. Если конфликт с rules/plan → stop and report

## Completion

- **Workflow task:** all selected findings resolved with evidence, final verification fresh
- **Ad hoc:** нет handoff к /cpdocs
- **Ad Hoc Save Gate:** если context-only, спросить перед сохранением

## Parallelization

- **По умолчанию:** sequential processing
- **Параллельная обработка:** только с explicit user approval

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| Review report | Файл или conversation | Да |
| Code files | Проект | Да |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |

## Outputs

- Исправленный код
- Мутированный review report с resolved/skipped/deferred статусами

## Subagents

| Роль | Tier | Назначение |
|------|------|------------|
| Fix agent | По сложности | Исправление одного finding |

## Dependencies

- **Requires:** завершённый `/cpreview` с findings
- **Next:** `/cpreview` (re-check) или `/cpdocs`

## Change Impact

- Изменение fix agent contract влияет на качество исправлений
- Изменение report mutation формата требует синхронизации с cpreview и cpresume
