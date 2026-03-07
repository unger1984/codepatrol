# cp-docs

## Purpose

Создание и обновление AI-facing документации в `.ai/docs/`. Поддерживает workflow-driven и ad hoc режимы.

## When to read

- Создание или обновление документации проекта
- Понимание двух режимов работы (workflow vs ad hoc)
- Настройка intent resolution для ad hoc запросов
- Понимание двухфазного runtime (analysis → writing)

## Scope

Покрывает весь процесс документирования: от intent resolution до validation. Не покрывает предшествующие этапы workflow.

## Related docs

- [cp-fix](cp-fix.md) — предыдущий шаг в workflow
- [cp-rules](cp-rules.md) — опциональный следующий шаг
- [Workflow](../../shared/workflow.md) — позиция в pipeline

---

## Role

**AI project memory maintainer.** Документирует стабильные, финальные знания о проекте. Не переносит временные рассуждения в `.ai/docs/`.

## Mode Detection

| Условие | Режим | Поведение |
|---------|-------|-----------|
| Active workflow task + completed code path | Workflow | Автономное решение что/где документировать |
| No workflow task | Ad hoc | Intent Resolution (интерактивно при неясности) |
| No args + no task + .ai/docs/ exists | — | Предложить варианты пользователю |
| No args + .ai/docs/ not exists | — | Предложить инициализацию |

## Ad Hoc Intent Resolution (5 steps)

### 1. Parse Intent
Из фразы пользователя извлечь:
- **action** — create / augment / restructure / check
- **subject** — project structure, data flow, module, API, etc.
- **format hints** — diagrams, tables, Mermaid types

### 2. Read Docs Structure
Прочитать `.ai/docs/README.md` (mandatory) — понять существующую структуру и навигацию.

### 3. Scope Decomposition
Один topic или несколько? Если несколько и группировка неясна → спросить:
- Один обзорный документ
- Отдельные документы по topic
- Группировка по theme

### 4. Target Resolution
Для каждого unit: augment existing или create new? Автономно если ясно, спросить если overlap.

### 5. Research Decision
- **Narrow scope** (single file/topic) → inline research
- **Broad scope** (multiple files/cross-cutting) → dispatch research субагент

## Runtime Flow (two phases)

### Analysis Phase (no writes)
1. Mode detection
2. Brief formation (workflow: autonomous / ad hoc: interactive)
3. Research (scope-aware: subagent for broad, inline for narrow)
4. Read relevant code and configs
5. Prepare drafts — exact content for each target doc

### Writing Phase (no new reasoning)
6. Apply drafts — write to files
7. Validate — scope-aware validation pass
8. Update workflow state (only in workflow mode)

**Полностью завершить analysis и drafts перед записью в любой файл.**

## Documentation Rules

- Документировать только stable, reusable project knowledge
- Держать README-based навигацию intact
- Размещать в `.ai/docs/domains/` или `.ai/docs/shared/`
- Язык: explicit project rules → active agent rules → English fallback

## Doc File Format

Каждый файл включает:
- purpose — что покрывает
- when to read — какие задачи делают doc релевантным
- scope — границы
- related docs — ссылки
- key modules and components
- relationships and dependencies
- constraints and rules
- change impact
- source of truth references

Default: Markdown + Mermaid (DFD, Sequence, module diagrams).

## Initialization

Если `.ai/docs/` не существует:
- `mkdir -p .ai/docs/ .ai/docs/domains/ .ai/docs/shared/` (idempotent)
- Создать README.md как navigation entry point
- Sources: project rules, CLAUDE.md/AGENTS.md, actual code

## Validation Pass (scope-aware)

| Scope | Проверки |
|-------|----------|
| Always | README.md references correct, content matches code |
| Broad (new docs, multiple files) | Full navigation integrity, no orphans, placement coherence |
| Narrow (single file augment) | Changed section consistent with rest of file |

## Blocker Policy

Stop и ask когда:
- Scope или source of truth не определяется
- Конфликт между code, artifacts, и existing docs
- Intent неясен после inference

## Inputs

| Input | Источник | Обязателен |
|-------|----------|------------|
| User phrase / workflow artifacts | Пользователь / task | Да |
| `.ai/docs/README.md` | Existing docs | Нет (если есть) |
| Project code | Codebase | Да |
| Правила проекта | CLAUDE.md / AGENTS.md | Да |

## Outputs

- Новые или обновлённые `.ai/docs/` файлы
- Обновлённый `README.md` с навигацией

## Subagents

| Роль | Tier | Назначение |
|------|------|------------|
| Research subagent | По model-policy | Broad-scope research (чтение кода/configs/docs) |

## Dependencies

- **Requires:** завершённый code path (в workflow) или user intent (в ad hoc)
- **Next:** `/cp-rules` (optional) или завершение workflow task

## Change Impact

- Изменение doc file format влияет на все существующие docs
- Изменение validation pass влияет на completeness criteria
- Изменение intent resolution влияет на ad hoc user experience
