[English](README.md) | **Русский**

# CodePatrol

AI-скиллы с осведомлённостью о проекте для [Claude Code](https://docs.anthropic.com/en/docs/claude-code) и [Codex CLI](https://github.com/openai/codex). Расширяет стандартный воркфлоу [Superpowers](https://github.com/obra/superpowers) знанием правил и документации проекта.

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

### Установка из Claude Marketplace

Найдите `codepatrol` в маркетплейсе Claude Code.

### Установка из последнего релиза

```bash
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install.sh | bash -s -- claude
```

### Установка из исходников

```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh claude   # или: ./install.sh codex
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


## Разработка

### Структура

```
templates/             # Исходные шаблоны (редактировать здесь)
├── _shared/           # Общие частичные файлы
├── cp-review/         # Скилл ревью + промпты ревьюеров
├── cp-fix/            # Скилл фиксов + промпт агента
└── using-codepatrol/  # Определения расширений

platforms/             # Платформенные env-файлы
├── claude.env
└── codex.env

skills/                # Сгенерированный вывод (не редактировать)
```

### Сборка

```bash
./install.sh build   # Пересобрать skills/ из шаблонов
./install.sh claude  # Собрать и установить в ~/.claude/skills/
./install.sh codex   # Собрать и установить в ~/.codex/skills/
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
- Поддержка Cursor пока не реализована
- Поддержка Codex CLI экспериментальная

## Лицензия

MIT
