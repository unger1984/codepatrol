[English](README.md) | **Русский**

# CodePatrol

Workflow-first набор скиллов для [Claude Code](https://docs.anthropic.com/en/docs/claude-code) и [Codex CLI](https://github.com/openai/codex). CodePatrol объединяет всю AI-ориентированную цепочку: исследования, дизайн, планирование, реализация, ревью, фиксы, документацию и правила проекта в одном наборе команд с шаблонами в `templates/` и платформенными значениями в `platforms/*.env`.

## Содержание

- [Быстрый старт](#быстрый-старт)
- [Зачем нужен CodePatrol](#зачем-нужен-codepatrol)
- [Обзор workflow](#обзор-workflow)
- [Хранение и организация данных](#хранение-и-организация-данных)
- [Как запускать](#как-запускать)
- [Пример сессии](#пример-сессии)
- [Установка](#установка)
- [Правила и контекст](#правила-и-контекст)
- [Разработка](#разработка)
- [CI/CD](#cicd)
- [Известные ограничения](#известные-ограничения)

## Быстрый старт

**Требования:** установленный [Claude Code](https://docs.anthropic.com/en/docs/claude-code) или [Codex CLI](https://github.com/openai/codex).

```bash
# 1. Установить скиллы
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install-remote.sh | bash

# 2. Открыть проект в Claude Code
cd your-project

# 3. Запустить первую задачу
/cpatrol добавить кэширование в API-слой
```

CodePatrol создаст `.ai/` в проекте, проведёт research, обсудит подход и подготовит дизайн + план. Дальше workflow подскажет следующую команду.

## Зачем нужен CodePatrol

- **Единый пользовательский опыт:** команды скрывают внутренние stage ID и управляют исследованием, дизайном, выполнением, проверками и документированием.
- **Контекст и память:** каждая команда начинает с `.ai/docs/README.md` и берет артефакты из `.ai/tasks/`, так агенты читают только релевантное.
- **Аудит:** `.ai/tasks/` содержит `<slug>.workflow.md`, `<slug>.design.md`, `<slug>.plan.md`, отчеты; изменения фиксируются только в полях отслеживания.

## Обзор workflow

```mermaid
---
title: Workflow задачи
---
flowchart LR
    subgraph design ["🔍 Проектирование"]
        direction TB
        cpatrol("/cpatrol")
        research["research\nclarification\napproach options"]
        des["design.md"]
        plan["plan.md"]
        cpatrol --> research --> des --> plan
    end

    subgraph plancheck ["📋 Ревью плана"]
        direction TB
        planreview("/cpplanreview")
        planfix("/cpplanfix")
        planreview -- "findings" --> planfix
        planfix -. "revalidation" .-> planreview
    end

    subgraph impl ["⚡ Реализация"]
        direction TB
        execute("/cpexecute")
        checkpoints["checkpoint-отчёты\nверификация по шагам"]
        execute --> checkpoints
    end

    subgraph review ["📝 Code Review"]
        direction TB
        cpreview("/cpreview")
        compliance["compliance pass"]
        quality["quality pass"]
        cpfix("/cpfix")
        cpreview --> compliance --> quality
        quality -- "findings" --> cpfix
        cpfix -. "revalidation" .-> cpreview
    end

    subgraph docs ["📚 Документация"]
        cpdocs("/cpdocs")
    end

    design -- "plan.md" --> plancheck
    plancheck -- "approved plan" --> impl
    impl -- "handoff" --> review
    review -- "verified" --> docs
    docs --> done([✅ Задача завершена])
```

```mermaid
---
title: Потоки данных и артефакты
---
flowchart TD
    subgraph storage [".ai/"]
        subgraph docsdir [".ai/docs/"]
            readme[("README.md\nнавигатор")]
            domains["domains/\nshared/"]
        end
        subgraph taskdir [".ai/tasks/‹timestamp›-‹slug›/"]
            workflow["workflow.md\nstate + стадии"]
            designf["design.md"]
            planf["plan.md"]
            reports["reports/\nplan-review · code-review"]
        end
        adhoc[".ai/reports/\nad-hoc отчёты"]
    end

    cpatrol2("/cpatrol") -- "создаёт" --> workflow
    cpatrol2 -- "создаёт" --> designf
    cpatrol2 -- "создаёт" --> planf
    planreview2("/cpplanreview") -- "пишет" --> reports
    cpfix2("/cpfix") -- "обновляет tracking" --> reports
    cpreview2("/cpreview") -- "пишет" --> reports
    cpreview2 -- "ad-hoc режим" --> adhoc
    cpdocs2("/cpdocs") -- "обновляет" --> docsdir
    cpresume2("/cpresume") -. "читает" .-> workflow
    cpresume2 -. "читает" .-> reports

    readme -. "точка входа\nдля всех команд" .-> cpatrol2
    readme -. "точка входа\nдля всех команд" .-> cpreview2
```

```mermaid
---
title: Вспомогательные команды
---
flowchart LR
    interrupted([Прерванная сессия]) --> cpresume("/cpresume")
    cpresume -- "определяет стадию\nпо workflow.md" --> resume_target(["→ продолжает с нужного шага"])

    experience([Накопленный опыт]) --> cprules("/cprules")
    cprules -- "анализирует отчёты\nи findings" --> proposals["предложения\nпо правилам"]
    proposals -- "после одобрения" --> rules[(".claude/rules/\nCLAUDE.md\nAGENTS.md")]
```

## Хранение и организация данных

CodePatrol создаёт в проекте директорию `.ai/`, которая служит двум целям: долговременная память проекта и артефакты текущих задач.

### `.ai/docs/` — память проекта

Постоянная AI-ориентированная документация. Это не дублирование обычных docs, а отдельный слой знаний, оптимизированный для агентов: архитектурные решения, паттерны проекта, domain-специфичные ограничения.

`README.md` внутри — обязательная точка входа. Каждая команда CodePatrol начинает чтение контекста именно с него, находит по навигации нужные docs и читает только релевантные. Это предотвращает бесцельное сканирование репозитория.

Создаётся и обновляется командой `/cpdocs` по результатам завершённых задач.

### `.ai/tasks/` — артефакты задач

Каждая workflow-задача живёт в своей директории: `.ai/tasks/<YYYY-MM-DD-HHMM>-<slug>/`.

Внутри — три основных файла, которые создаёт `/cpatrol` и обновляют последующие команды:

- **`<slug>.workflow.md`** — центральный state-файл. Хранит текущую стадию, статус, ссылки на артефакты, трекинг прохождения стадий и ключевые решения. Именно по нему `/cpresume` определяет, откуда продолжить работу.
- **`<slug>.design.md`** — дизайн решения. Формируется в `/cpatrol` после research и обсуждения подходов. Один на задачу, правится итеративно.
- **`<slug>.plan.md`** — план реализации. Один на задачу, проходит `/cpplanreview` перед исполнением.

Внутри задачи также есть `reports/` — отчёты ревью плана и кода. Отчёты являются audit-артефактами: `/cpplanfix` и `/cpfix` обновляют в них только tracking-поля (статус, способ решения, заметки), но не удаляют и не переписывают findings.

### `.ai/reports/` — ad-hoc отчёты

Отчёты вне workflow-задач. Например, `/cpreview` для произвольной ветки или PR сохраняет результат сюда, а не в task-директорию.

### Зачем это нужно

- **Возобновляемость.** Задачу можно продолжить в новой сессии через `/cpresume` — весь контекст в артефактах, а не в памяти чата.
- **Аудит.** История решений и findings не теряется — отчёты накопительные, workflow.md фиксирует ключевые развилки.
- **Изоляция контекста.** Агенты читают `.ai/docs/README.md` → нужные docs → артефакты задачи → код. Без bulk-чтения репозитория.

## Как запускать

Команды вводятся в Claude Code или Codex CLI. Каждая команда сама находит нужные артефакты из `.ai/tasks/` и `.ai/docs/`. Если контекст неясен — команда спросит.

### Полный workflow задачи

Workflow строится вокруг одной задачи: одна задача = один дизайн + один план. Задача считается завершённой только после обновления AI-документации.

**1. Старт — `/cpatrol`**

Единая точка входа. Команда проверяет, нет ли незавершённых задач, и предлагает продолжить их или начать новую. Для новой задачи запускается обязательная цепочка:
- **research** — сбор контекста из `.ai/docs/`, кода и правил проекта;
- **clarification** — уточнение неясных моментов у пользователя;
- **approach options** — сравнение подходов с trade-offs и рекомендацией;
- **design** — формирование `design.md`;
- **plan** — формирование `plan.md`.

Глубина процесса адаптируется под задачу: для мелких правок — минимальная, для крупных фич — полная.

**2. Ревью плана — `/cpplanreview` → `/cpplanfix`**

Перед реализацией план проверяется на соответствие дизайну, правилам проекта и готовности к исполнению. `/cpplanreview` сохраняет отчёт с findings, `/cpplanfix` закрывает их и проводит bounded revalidation.

**3. Реализация — `/cpexecute`**

Выполняет утверждённый план по шагам с checkpoint-отчётами. Останавливается на блокерах вместо угадывания. По завершении предлагает перейти к code review — в текущей сессии или передать в новую.

**4. Code review — `/cpreview` → `/cpfix`**

`/cpreview` сначала проверяет compliance (соответствие дизайну, плану и правилам), затем quality (архитектура, стиль, тесты, безопасность). Отчёт сохраняется как `.review.report.md`. `/cpfix` исправляет findings в порядке приоритета: сначала compliance, потом quality.

**5. Документация — `/cpdocs`**

Обновляет AI-ориентированную документацию в `.ai/docs/` на основе результатов задачи. Проводит validation pass: проверяет навигацию, размещение и соответствие коду.

### Вспомогательные команды

- `/cpresume` — продолжить незавершённую задачу. Загружает артефакты, определяет текущую стадию и показывает, что делать дальше.
- `/cprules` — не входит в обязательный workflow. Анализирует накопленные результаты (отчёты, повторяющиеся findings) и предлагает улучшения правил проекта. Изменения применяются только после подтверждения пользователя.

### Примечания

- Любой команде можно передать путь к конкретному артефакту: `/cpresume .ai/tasks/2026-03-06-1420-my-task/`.
- `/cpreview` также работает вне workflow — можно ревьюить ветку, PR, директорию или набор файлов.
- Если команда спрашивает «какой артефакт?», ответьте путём или коротко: «текущая задача», «новая задача».

## Пример сессии

```
> /cpatrol добавить rate limiting для API

🔍 Research: читаю .ai/docs/README.md → docs/domains/api.md → src/api/...
Найдено: Express + Redis, 12 эндпоинтов, аутентификация через JWT.

❓ Уточнение:
  1. Лимитировать все эндпоинты одинаково или разделить по группам?
  2. Хранить счётчики в Redis (уже в проекте) или in-memory?
  → Рекомендую: Redis + разные лимиты для auth и data эндпоинтов.

> 1 — по группам, 2 — Redis, согласен с рекомендацией

📐 Design: создан .ai/tasks/2026-03-06-1420-rate-limiting/rate-limiting.design.md
📋 Plan: создан rate-limiting.plan.md (3 этапа, 8 шагов)
   Следующий шаг → /cpplanreview

> /cpplanreview

✅ Findings: 1 minor (не указан fallback при недоступности Redis)
   Следующий шаг → /cpplanfix

> /cpplanfix

🔧 Исправлено: добавлен fallback на in-memory counter.
   Revalidation пройдена. Следующий шаг → /cpexecute

> /cpexecute

⚡ Этап 1/3: middleware создан, тесты проходят
⚡ Этап 2/3: конфиг лимитов по группам, интеграционные тесты ок
⚡ Этап 3/3: документация обновлена
   Реализация завершена. Следующий шаг → /cpreview

> /cpreview

📝 Compliance: ок (соответствует дизайну и плану)
📝 Quality: 1 important (middleware не логирует rejected запросы)
   Отчёт: .ai/tasks/.../reports/...-rate-limiting.review.report.md
   Следующий шаг → /cpfix

> /cpfix

🔧 Добавлено логирование. Верификация пройдена.
   Следующий шаг → /cpdocs

> /cpdocs

📚 Обновлён .ai/docs/domains/api.md (добавлена секция rate limiting)
   Задача завершена.
```

## Установка

### Последний релиз

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install-remote.sh | bash

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install-remote.sh | bash -s codex
```

### Claude marketplace plugin

```text
/plugin marketplace add unger1984/codepatrol
/plugin install codepatrol@codepatrol-marketplace
```

### Из исходников

```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh claude
./install.sh codex
```

Installer удаляет legacy review-директории и устанавливает только текущий набор workflow-команд.

## Правила и контекст

### Откуда берутся правила проекта

CodePatrol не вводит свой формат правил — он использует то, что уже есть в платформе:

| Платформа | Источники правил |
|-----------|-----------------|
| Claude Code | `.claude/rules/*.md`, `CLAUDE.md` |
| Codex CLI | `AGENTS.md` |

Команды `/cpreview`, `/cpplanreview` и `/cpexecute` автоматически читают правила проекта и учитывают их при ревью, валидации плана и реализации. `/cprules` анализирует накопленные результаты и предлагает добавить или обновить правила.

### Языковая политика

CodePatrol автоматически адаптирует язык под проект:

1. **Правила проекта** — если в `CLAUDE.md` или `AGENTS.md` указан язык (например, «Responses in Russian»), все артефакты (`design.md`, `plan.md`, отчёты, `.ai/docs/`) и ответы пользователю будут на этом языке.
2. **Язык клиента** — если правила проекта не задают язык, используется язык, настроенный в агенте или клиенте.
3. **Fallback** — если язык нигде не указан, артефакты создаются на английском.

Исключение: `workflow.md` всегда ведётся на английском — это state-файл для агентов, а не документация.

### Контекст и `.ai/docs/`

Все команды начинают чтение контекста с `.ai/docs/README.md` и по навигации находят нужные docs. Это предотвращает ситуации, когда агент сканирует весь репозиторий «на всякий случай», и обеспечивает стабильное поведение даже в больших кодовых базах.

## Разработка

```text
templates/                        source-of-truth шаблоны скиллов
platforms/                        платформенные значения placeholder'ов
skills/                           сгенерированный output из ./install.sh build
.claude-plugin/                   манифесты Claude marketplace
install.sh                        локальная сборка и установка
install-remote.sh                 installer для релизов
```

```bash
./install.sh build
./install.sh claude
./install.sh codex
```

## CI/CD

CI пересобирает `skills/`, проверяет актуальность generated output, валидирует substitution placeholder'ов и ожидаемую структуру runtime-навыков `cpatrol` / `cp*` для release assets.

## Известные ограничения

- Основная проверка была на macOS.
- Поддержка Cursor пока не реализована.

## Лицензия

MIT
