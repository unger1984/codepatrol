# cp-resume

## Purpose

Восстановление прерванной работы из предыдущей сессии. Определяет текущую фазу и формирует handoff state для продолжения.

## When to read

- Продолжение работы из прошлой сессии
- Понимание resumability model
- Отладка detection logic для фаз
- Добавление нового stage в workflow

## Scope

Покрывает загрузку артефактов, определение фазы и формирование handoff. Не покрывает выполнение самой работы.

## Related docs

- [Workflow](../../shared/workflow.md) — полный pipeline и artifact storage
- [Skills Reference](../skills-reference.md) — все скиллы

---

## Role

**Session recovery agent.** Восстанавливает контекст из артефактов и определяет точку продолжения.

## Accepted Inputs

| Input | Описание |
|-------|----------|
| Workflow artifact path | Полный путь к файлу |
| Task directory | `.ai/tasks/<YYYY-MM-DD-HHMM-slug>/` |
| `workflow.md` | Файл статуса задачи |
| `design.md` | Файл дизайна |
| `plan.md` | Файл плана |
| Report file | Файл отчёта из `reports/` |
| *(no argument)* | Поиск resumable tasks в `.ai/tasks/` → выбор пользователем |

## Resume Process

### 1. Load Artifacts

Минимальный набор для восстановления контекста:
- `<task-slug>.workflow.md`
- `<task-slug>.design.md` (if present)
- `<task-slug>.plan.md` (if present)
- Open review reports (if present)
- `.ai/docs/README.md` (for additional research context)

### 2. Detect Current Phase

Автоматическое определение текущей фазы по состоянию артефактов:

| Phase | Display name | Признак |
|-------|-------------|---------|
| Research | research | workflow.md без design/plan |
| Clarification | clarification | research done, вопросы открыты |
| Approach | approach options | clarification done |
| Design | design | approach выбран |
| Plan | plan | design done |
| Plan review | plan review | plan done |
| Plan fix | review fixes | plan-review report с open findings |
| Plan revalidation | plan revalidation | plan fixes done |
| Execution | execution | plan approved |
| Code review | code review | execution done |
| Code fix | review fixes | review report с open findings |
| Docs | AI docs update | code review approved |

Правило: prefer latest unfinished mandatory stage. Если reports с open findings → resume from matching fix stage.

### 3. Reconstruct Handoff State

| Поле | Описание |
|------|----------|
| Task objective | Цель задачи из workflow.md |
| Current status | Текущий статус |
| Last completed verified stage | Последний подтверждённый этап |
| Open blockers | Нерешённые блокеры |
| Recommended next command | `/cp-xxx` команда для продолжения |

## Resumability Rules

- Reports — **append-only** (кроме tracking fields: Status, Resolved via, Resolution notes)
- Task resumable пока `Status: in-progress` в workflow.md
- Display names сохраняются для пользователя

## Usage Examples

```
/cp-resume .ai/tasks/2026-03-06-1420-ai-workflow/
/cp-resume .ai/tasks/2026-03-06-1420-ai-workflow/ai-workflow.workflow.md
/cp-resume .ai/tasks/.../reports/2026-03-06-1540-ai-workflow.plan-review.report.md
```

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| Artifact path / task dir | Пользователь или auto-discovery | Да |
| Workflow artifacts | `.ai/tasks/` | Да |

## Outputs

- Handoff state в conversation (objective, status, blockers, next command)
- Вызов рекомендованного скилла

## Subagents

Не использует субагентов.

## Dependencies

- **Requires:** существующие workflow artifacts
- **Next:** любой скилл в зависимости от detected phase

## Change Impact

- Добавление нового workflow stage требует обновления detection logic
- Изменение формата артефактов требует обновления парсинга
- Изменение display names влияет на UX при resume
