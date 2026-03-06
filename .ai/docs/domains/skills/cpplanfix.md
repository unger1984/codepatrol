# cpplanfix

## Purpose

Обработка open findings из отчёта `/cpplanreview` — исправление, пропуск или отложение каждого.

## When to read

- Исправление проблем в плане после review
- Понимание механики incremental report mutation
- Настройка fix policy (auto vs manual)
- Работа с parallelization approval

## Scope

Покрывает обработку findings и мутацию отчёта. Не покрывает сам review (→ cpplanreview).

## Related docs

- [cpplanreview](cpplanreview.md) — источник findings
- [cpexecute](cpexecute.md) — следующий шаг после исправления
- [cpfix](cpfix.md) — аналогичная механика для code review findings

---

## Role

**Technical lead (fixing).** Разбирает findings, принимает решения по каждому, применяет fix.

## Process

1. **Load report** — из explicit path, workflow task, или conversation context
2. **Filter** — только findings со `Status: open`, в порядке отчёта
3. **Create progress items** — по одному на каждый open finding (с номером и severity)
4. **Classify each finding:**
   - **Auto-fix** — разрешение локальное, intent ясен, нет trade-offs
   - **Ask-user** — несколько валидных вариантов, scope/architecture impact, конфликт с constraints, недостаточно контекста
5. **Process** — в порядке отчёта, обновляя report после каждого
6. **Bounded revalidation** — только на изменённых секциях

## Incremental Report Mutation (mandatory)

После обработки каждого finding (не в batch!):

1. Применить fix к плану
2. Запустить bounded revalidation на изменённых секциях
3. **Немедленно обновить файл отчёта** (если существует):
   - `Status: open` → `resolved | skipped | deferred`
   - `Resolved via: <что изменено>`
   - `Resolution notes: <объяснение>`
4. Отметить progress item как completed

Если файл не существует (context-only) → записать обновление в conversation memory.

## Parallelization

- **По умолчанию:** sequential processing
- **Параллельная обработка:** только с явным одобрением пользователя

## Ad Hoc Save Gate

Если findings переданы через conversation (нет файла отчёта):
- Нельзя писать в файл до явного выбора пользователя
- Предложить: "Save report to file" или "Do not save"

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| Plan review report | Файл или conversation | Да |
| `plan.md` | Workflow task | Да |
| `workflow.md` | Workflow task | Нет |

## Outputs

- Обновлённый `plan.md` с исправлениями
- Мутированный report с resolved/skipped/deferred статусами

## Subagents

Не использует субагентов напрямую (может быть расширено в будущем).

## Dependencies

- **Requires:** завершённый `/cpplanreview` с findings
- **Next:** `/cpplanreview` (re-check) или `/cpexecute`

## Change Impact

- Изменение формата report mutation влияет на cpresume detection
- Изменение fix policy влияет на уровень автоматизации
