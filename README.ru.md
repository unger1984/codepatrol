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
- Подходы проверяются на соответствие конвенциям проекта
- Планы включают шаги обновления документации
- Планы проходят self-check на соответствие правилам
- Специализированное двухпроходное ревью (compliance + quality)

## Скиллы

| Скилл | Назначение |
|-------|-----------|
| `using-codepatrol` | Расширяет brainstorming и writing-plans осведомлённостью о проекте |
| `/cp-review` | Двухпроходное ревью: compliance (дизайн + план + правила), затем quality (5 специализированных ревьюеров) |
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

**Из исходников (Unix/macOS):**
```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh claude
```

**Из исходников (Windows):**
```powershell
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
.\install.ps1 claude
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

**Из исходников (Unix/macOS):**
```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh codex
```

**Из исходников (Windows):**
```powershell
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
.\install.ps1 codex
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

**Из исходников (Unix/macOS):**
```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh cursor
```

**Из исходников (Windows):**
```powershell
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
.\install.ps1 cursor
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

**Из исходников (Unix/macOS):**
```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh opencode
```

**Из исходников (Windows):**
```powershell
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
.\install.ps1 opencode
```

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
├── _shared/           # Общие частичные файлы
├── cp-review/         # Скилл ревью + промпты ревьюеров
├── cp-fix/            # Скилл фиксов + промпт агента
├── cp-docs/           # Скилл документации
└── using-codepatrol/  # Определения расширений

platforms/             # Платформенные env-файлы
├── claude.env
├── codex.env
├── cursor.env
└── opencode.env

skills/                # Сгенерированный вывод (не редактировать)
```

### Сборка

**Unix/macOS:**
```bash
./install.sh build   # Пересобрать skills/ из шаблонов
./install.sh claude  # Собрать и установить в ~/.claude/skills/
./install.sh codex   # Собрать и установить в ~/.codex/skills/
./install.sh cursor  # Собрать и установить в ~/.cursor/skills/
./install.sh opencode # Собрать и установить в ~/.config/opencode/skills/
```

**Windows (PowerShell):**
```powershell
.\install.ps1 build   # Пересобрать skills/ из шаблонов
.\install.ps1 claude  # Собрать и установить в ~/.claude/skills/
.\install.ps1 codex   # Собрать и установить в ~/.codex/skills/
.\install.ps1 cursor  # Собрать и установить в ~/.cursor/skills/
.\install.ps1 opencode # Собрать и установить в ~/.config/opencode/skills/
```

### Правила шаблонов

- Шаблоны должны быть универсальными — без привязки к языкам или фреймворкам
- Платформенные значения в `platforms/*.env`, ссылки через `{{VAR_NAME}}`
- Общий контент в `templates/_shared/`, ссылки через `{{@include:path}}`
- Платформенные варианты через `{{@platform-include:name}}` → `_shared/{name}-{platform}.md`
- Контент скиллов на английском; LLM адаптируется к языку пользователя в рантайме

## CI/CD

- **ci.yml** — валидация шаблонов, проверка сборки, линтинг на PR
- **release.yml** — создание GitHub-релизов из тегов версий
- **validate-release.yml** — предрелизная валидация

## Известные ограничения

- Протестировано только на macOS
- Поддержка OpenCode экспериментальная

## Лицензия

MIT
