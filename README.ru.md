[English](README.md) | **Русский**

# CodePatrol

AI-скиллы с осведомлённостью о проекте для [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Codex CLI](https://github.com/openai/codex), [Cursor](https://cursor.com) и [OpenCode](https://opencode.ai). Расширяет стандартный воркфлоу [Superpowers](https://github.com/obra/superpowers) знанием правил и документации проекта.

## Содержание

- [Как это работает](#как-это-работает)
- [Скиллы](#скиллы)
- [Хранение данных](#хранение-данных)
- [Быстрый старт](#быстрый-старт)
  - [Claude Code](#claude-code)
  - [Codex CLI](#codex-cli)
  - [Cursor](#cursor)
  - [OpenCode](#opencode)
  - [Oh My Pi](#oh-my-pi)
- [Использование](#использование)
- [Разработка](#разработка)
- [CI/CD](#cicd)
- [Известные ограничения](#известные-ограничения)
- [Лицензия](#лицензия)

## Как это работает

CodePatrol встраивается в цепочку скиллов Superpowers (`brainstorming → writing-plans → executing-plans`), а не заменяет её:

```
brainstorming (superpowers)          writing-plans (superpowers)
+ расширения CodePatrol:             + расширения CodePatrol:
│                                    │
├─ Читает правила проекта            ├─ Читает правила проекта
├─ Читает .ai/docs/                  ├─ Читает .ai/docs/
├─ Проверяет подходы vs правила      ├─ Включает шаг обновления доков
├─ Сохраняет дизайн в .ai/tasks/     ├─ Self-check плана vs правила
│                                    ├─ Сохраняет план в .ai/tasks/
▼                                    ▼
writing-plans                        executing-plans / subagent-driven
                                     │
                                     ▼ (по решению пользователя)
                                     /cp-review → /cp-fix → /cp-docs
```

**Что добавляет CodePatrol:**
- Правила и документация проекта читаются **до** дизайна и планирования
- Planning self-check использует цитируемый prepared context: путь и тип артефакта, явные требования, только применимые выдержки из правил и доков, выдержки из утверждённого дизайна для планов и blockers по недостающему контексту
- Шаг обновления документации попадает в план только когда существующие доки действительно надо менять
- `/cp-review` сохраняет приоритет compliance, использует adaptive quality routing для большого low-risk scope и не сливает independent security review с architecture-risk review
- `/cp-fix` использует Manual Per Item Gate и `auto safe fixes` только для одного изолированного безопасного варианта
- Для docs/rules-исследований используются source maps (`path:line`, точная цитата, relevance), а progress tracking батчится с ближайшим реальным действием, если платформа это умеет
- Для OMP дублирование output schema оставлено намеренно; CodePatrol **не** добавляет YAML frontmatter include/preprocessor для этого случая

## Скиллы

| Скилл | Назначение |
|-------|-----------|
| `using-codepatrol` | Расширяет brainstorming и writing-plans осведомлённостью о проекте |
| `/cp-review` | Обязательный локальный compliance triage, затем quality после чистого compliance; powerful compliance review только для применимых контрактов или high-risk scope |
| `/cp-fix` | Обработка и исправление findings с инкрементальным трекингом |
| `/cp-docs` | Создание и ведение AI-документации проекта |

## Хранение данных

```
.ai/
├── tasks/                          # Артефакты задач
│   └── YYYY-MM-DD-HHMM-slug/
│       ├── design.md               # Утверждённый дизайн
│       ├── plan.md                  # План реализации
│       └── review.md               # Отчёт code review
├── docs/                           # AI-документация проекта
│   └── README.md                   # Навигационный хаб
└── reports/                        # Ad-hoc отчёты ревью
```

## Быстрый старт

### Claude Code

**Из последнего релиза (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- claude
```

**Из последнего релиза (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 claude
```


### Codex CLI

**Из последнего релиза (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- codex
```

**Из последнего релиза (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 codex
```


### Cursor

**Из последнего релиза (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- cursor
```

**Из последнего релиза (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 cursor
```


### OpenCode

**Из последнего релиза (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- opencode
```

**Из последнего релиза (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 opencode
```


### Oh My Pi

**Из последнего релиза (Unix/macOS):**
```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- omp
```

**Из последнего релиза (Windows):**
```powershell
irm https://raw.githubusercontent.com/unger1984/codepatrol/main/install.ps1 -OutFile install.ps1; .\install.ps1 omp
```


Установщик добавляет скиллы в `~/.omp/agent/skills` и восемь агентов CodePatrol в
`~/.omp/agent/agents`: три для ревью, три для исправлений и два для self-check планирования. Они разрешают
`@slow`, `@task` и `@smol` через ваши `modelRoles`; дублирование OMP output schema сохранено намеренно, потому что CodePatrol не добавляет YAML frontmatter include/preprocessor для них.

## Использование

### Начало новой задачи

Просто опишите что хотите сделать. CodePatrol автоматически расширяет brainstorming:

```
> Давай добавим rate limiting к API

# brainstorming читает правила и доки проекта,
# задаёт уточняющие вопросы, предлагает подходы,
# проверяет их на соответствие конвенциям,
# создаёт дизайн → затем план
```

### Ревью кода

```
> /cp-review
> /cp-review src/auth/
> /cp-review branch vs main
```

### Исправление findings

```
> /cp-fix
> /cp-fix .ai/tasks/2026-03-09-1420-rate-limit/review.md
```

### Обновление документации

```
> /cp-docs
> /cp-docs .ai/tasks/2026-03-09-1420-rate-limit/
```


## Разработка

### Структура

```
templates/             # Исходные шаблоны (редактировать здесь)
├── _shared/           # Общие partials: reviewer/fixer dispatch, planning self-checks, research contract
├── cp-review/         # Скилл ревью + промпты ревьюеров
├── cp-fix/            # Скилл фиксов + промпт агента
├── cp-docs/           # Скилл документации
└── using-codepatrol/  # Расширения планирования

platforms/             # Платформенные env-файлы
├── claude.env
├── codex.env
├── cursor.env
└── opencode.env

skills/                # Сгенерированный вывод (не редактировать)
```

### Валидация для разработчиков

Локальная генерация предназначена только для разработки репозитория. Пользователи устанавливают CodePatrol только командами удалённой установки выше.

```bash
./install.sh build      # Пересобрать Claude skills/ из шаблонов
./install.sh validate   # Сгенерировать все платформы во временных каталогах и проверить контракты
```

`install.ps1` поддерживается для удалённой установки на Windows; локальная валидация разработки выполняется POSIX-скриптом.

### Правила шаблонов

- Шаблоны должны быть универсальными — без привязки к языкам или фреймворкам
- Платформенные значения в `platforms/*.env`, ссылки через `{{VAR_NAME}}`
- Общий контент в `templates/_shared/`, ссылки через `{{@include:path}}` или `{{@platform-include:name}}`
- Контент скиллов остаётся на английском; в рантайме модель адаптируется к языку пользователя
- Не добавляйте YAML frontmatter include/preprocessor для дублирующегося OMP output-schema текста; это дублирование должно оставаться явным

## CI/CD

- **ci.yml** — валидация шаблонов, проверка сборки, линтинг на PR
- **release.yml** — создание GitHub-релизов из тегов версий
- **validate-release.yml** — предрелизная валидация

## Известные ограничения

- Протестировано только на macOS
- Поддержка OpenCode экспериментальная

## Лицензия

MIT
