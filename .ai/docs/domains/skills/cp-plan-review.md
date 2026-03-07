# cp-plan-review

## Purpose

Валидация плана реализации на корректность, соответствие дизайну и готовность к выполнению.

## When to read

- Проверка плана перед реализацией
- Понимание формата plan-review report
- Настройка чек-листа проверок
- Работа с ad hoc save gate

## Scope

Покрывает проверку плана и формирование отчёта. Не покрывает исправление findings (→ cp-plan-fix).

## Related docs

- [cp-plan](cp-plan.md) — предыдущий шаг: создание плана
- [cp-plan-fix](cp-plan-fix.md) — следующий шаг при findings
- [cp-execute](cp-execute.md) — следующий шаг при отсутствии findings

---

## Role

**Technical reviewer.** Анализирует план на полноту, согласованность и исполнимость.

## Review Checklist

1. Согласованность плана с утверждённым design
2. Покрытие всех необходимых шагов реализации
3. Безопасность и реалистичность execution model
4. Возможность улучшения плана (снижение контекста, параллелизация)
5. Явные и достаточные verification steps
6. Учёт побочных эффектов: docs, install, release, operational impact
7. Отсутствие scope creep

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| `plan.md` | Workflow task | Да |
| `workflow.md` | Workflow task | Да |
| `design.md` | Workflow task | Нет (если создавался) |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |
| Документация проекта | `.ai/docs/README.md` | Нет |

## Output

### Report Format

```markdown
## Plan Review Report

### Summary
- Plan: <task slug and path>
- Critical: N | Important: N | Minor: N
- Assessment: NEEDS_CHANGES | APPROVED | APPROVED_WITH_NOTES

### Critical Issues
[CATEGORY] — description
Fix: конкретное решение
Status: open
Resolved via:
Resolution notes:
```

### Report Storage

| Mode | Путь | Условие сохранения |
|------|------|--------------------|
| Workflow task | `.ai/tasks/<task>/reports/YYYY-MM-DD-HHMM-<slug>.plan-review.report.md` | Автоматически |
| Ad hoc | `.ai/reports/YYYY-MM-DD-HHMM-<scope>.plan-review.report.md` | Только после явного выбора пользователя |

## Execution Model

| Масштаб плана | Стратегия |
|---------------|-----------|
| Simple | Оркестратор выполняет все checks |
| Medium/Large | Субагенты по группам проверок |

## Ad Hoc Save Gate (critical)

Если нет активной workflow задачи:
1. Отчёт генерируется **только в conversation**
2. **Нельзя** писать в файл до явного выбора пользователя
3. Предложить: "Save to file" или "Run /cp-plan-fix now"
4. Нарушение gate — критическая ошибка workflow

## Subagents

Для medium/large планов — dispatch по группам проверок. Тиеры определяются model-policy.

## Dependencies

- **Requires:** завершённый `/cp-plan` (plan.md exists)
- **Next:** `/cp-plan-fix` (если findings) или `/cp-execute` (если APPROVED)

## Change Impact

- Изменение чек-листа влияет на то, какие проблемы обнаруживаются
- Изменение формата отчёта требует обновления cp-plan-fix (парсинг) и cp-resume (detection)
