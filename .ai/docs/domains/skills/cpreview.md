# cpreview

## Purpose

Двухпроходный code review: сначала compliance (соответствие дизайну, плану, правилам), затем quality (архитектура, безопасность, тесты, стиль).

## When to read

- Проведение code review
- Понимание двухпроходной модели и порядка проверок
- Настройка специализированных reviewer-субагентов
- Работа с report format и severity levels
- Понимание ad hoc save gate

## Scope

Покрывает review процесс, reviewer-субагентов, формат отчёта. Для исправления findings → [cpfix](cpfix.md). Для детальной механики review → [Review System](../review-system.md).

## Related docs

- [cpexecute](cpexecute.md) — предыдущий шаг: реализация
- [cpfix](cpfix.md) — следующий шаг при findings
- [cpdocs](cpdocs.md) — следующий шаг при отсутствии findings
- [Review System](../review-system.md) — подробная механика review

---

## Role

**Multi-dimensional reviewer.** Проводит compliance и quality review, dispatch-ит специализированных reviewer-субагентов, формирует единый отчёт.

## Scope Modes

Review может работать с разными scope:

- Current workflow task
- Current working tree
- Staged changes
- Committed branch diff
- Branch vs branch
- PR/MR diff
- Entire project
- Explicit file/directory paths

## Two-Pass Review Model

### Pass 1 — Compliance (mandatory first)

Проверка соответствия:
- Утверждённому design (`design.md`)
- Плану реализации (`plan.md`)
- Workflow decisions из `workflow.md`
- Правилам проекта (CLAUDE.md / AGENTS.md)

### Pass 2 — Quality

Четыре измерения, каждое с опциональным специализированным reviewer:

| Dimension | Reviewer file | Starting tier |
|-----------|--------------|---------------|
| Architecture | `architecture-reviewer.md` | default |
| Security | `security-reviewer.md` | default |
| Testing | `testing-reviewer.md` | default |
| Conventions | `codestyle-reviewer.md` | fast |

**Quality pass запускается только после того, как compliance pass acceptable.**

## Specialized Reviewers

### Architecture Reviewer
- Module boundaries и single responsibility
- Dependency direction (no circular)
- Layering rules
- Composition over inheritance
- Dead code removal
- Plan compliance

### Security Reviewer
- Injection prevention (SQL, command, path traversal)
- Secrets и sensitive data exposure
- Input validation
- Authorization и IDOR
- Error handling (no sensitive data в errors)
- Concurrency safety

### Testing Reviewer
- Test coverage для new/changed code
- Test quality и edge cases
- Test isolation
- Anti-patterns

### Codestyle Reviewer
- Naming conventions
- Code formatting
- Project style consistency
- Forbidden patterns

## Execution Model

| Scope | Strategy |
|-------|----------|
| Simple (few files) | Оркестратор выполняет оба pass |
| Medium/Large | Dispatch специализированных reviewer-субагентов параллельно |

Compliance pass всегда использует **powerful** tier (самая критичная проверка).

## Report Format

```markdown
## Code Review Report

### Summary
- Scope: N files (description)
- Critical: N | Important: N | Minor: N
- Assessment: NEEDS_CHANGES | APPROVED | APPROVED_WITH_NOTES

### Critical Issues
1. [CATEGORY] `file:line` — description
   **Finding type:** compliance | quality
   **Fix:** concrete solution
   **Status:** open
   **Resolved via:**
   **Resolution notes:**

### Strengths
- ...
```

### Severity Levels

| Level | Meaning |
|-------|---------|
| Critical | Must fix — correctness, security, compliance violation |
| Important | Should fix — architecture, maintainability |
| Minor | Nice to fix — style, minor improvements |

### Assessment Values

| Assessment | Meaning |
|------------|---------|
| `NEEDS_CHANGES` | Critical или important findings |
| `APPROVED_WITH_NOTES` | Только minor findings |
| `APPROVED` | Нет findings |

## Report Storage

| Mode | Путь | Условие |
|------|------|---------|
| Workflow task | `.ai/tasks/<task>/reports/YYYY-MM-DD-HHMM-<slug>.review.report.md` | Автоматически |
| Ad hoc | `.ai/reports/YYYY-MM-DD-HHMM-<scope>.review.report.md` | Только после Save Gate |

## Ad Hoc Save Gate (critical)

Если нет активной workflow задачи:
1. Отчёт генерируется **только в conversation**
2. Нельзя писать в файл до явного выбора пользователя
3. Предложить: "Save to file" или "Run /cpfix now"

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| Code changes | Git diff / file paths | Да |
| `design.md` | Workflow task | Нет |
| `plan.md` | Workflow task | Нет |
| `workflow.md` | Workflow task | Нет |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |

## Outputs

- Review report (в conversation или файл)

## Subagents

| Роль | Tier | Назначение |
|------|------|------------|
| Compliance reviewer | powerful | Проверка соответствия design/plan/rules |
| Architecture reviewer | default | Архитектурное качество |
| Security reviewer | default | Безопасность |
| Testing reviewer | default | Покрытие и качество тестов |
| Codestyle reviewer | fast | Стиль и conventions |

## Dependencies

- **Requires:** завершённый `/cpexecute` (в workflow) или код для review (в ad hoc)
- **Next:** `/cpfix` (если findings) или `/cpdocs` (если APPROVED)

## Change Impact

- Добавление нового reviewer dimension: создать template, обновить dispatch logic
- Изменение report format: влияет на cpfix (парсинг), cpresume (detection), cprules (анализ)
- Изменение severity levels: влияет на assessment logic
