# Дизайн AI Workflow

## Цель

Спроектировать для CodePatrol workflow-first систему, заточенную под персональный процесс работы пользователя в Codex и Claude.

Система должна:
- стартовать из одной умной точки входа;
- сначала изучать контекст проекта, а уже потом проектировать, планировать и реализовывать;
- вести по одной задаче один дизайн и один план;
- отдельно ревьюить и фиксить план и код;
- выполнять план через оркестратор исполнения;
- хранить состояние workflow и артефакты задачи в предсказуемой структуре `.ai`;
- после завершения работы обновлять AI-ориентированную документацию проекта;
- отдельно, по запросу, анализировать накопленные результаты и предлагать улучшения правил проекта.

Этот дизайн намеренно workflow-first, а не agent-first. Команды являются внешним UX. Внутри используются специализированные навыки, роли и агенты по стадиям.

## Модель продукта

Система состоит из:
- одной основной точки входа;
- отдельных review/fix-контуров для плана и кода;
- оркестратора исполнения для реализации;
- обновлятора AI-документации;
- отдельного ручного инструмента для улучшения project rules.

Основной принцип:
- внешний UX должен оставаться компактным;
- внутренние стадии workflow могут быть узкоспециализированными и строгими;
- агенты должны читать только минимально необходимый контекст;
- project rules и зафиксированные решения проекта всегда имеют приоритет над дефолтами workflow.

Реализация этого дизайна должна полностью заменить текущую project skill system:
- старая workflow-oriented skill system не рассматривается как часть целевой архитектуры;
- legacy skills, agent prompts и generated runtime artifacts не должны сохраняться как параллельный совместимый слой;
- source of truth для новой системы должен жить в новых шаблонах и генерировать целевые platform-specific outputs без смешения со старым workflow behavior.

Language policy:
- internal reusable instruction layer должен быть authored in English;
- к этому слою относятся skill templates, `SKILL.md`, reusable agent/subagent prompts, internal command definitions и другие переиспользуемые runtime instructions;
- project-facing workflow artifacts должны использовать язык, определенный project rules или active agent/client rules;
- к таким артефактам относятся `.ai/docs`, design/plan files, review reports и code comments, если они создаются системой;
- `workflow.md` является исключением: это agent-facing state artifact, поэтому он должен вестись на English независимо от project-facing language policy;
- если language policy нигде явно не задана, fallback language для project-facing artifacts — English;
- user-facing communication тоже должна следовать active agent/client language rules, а не внутреннему языку reusable instructions.

Language resolution order должен быть явным:
- для project-facing artifacts implementation должна сначала искать explicit project language rules;
- если project language rule не задано, нужно использовать active agent/client language rules;
- если и они не задают язык, fallback language для artifacts — English;
- для user-facing communication дополнительно допустимо учитывать язык текущего диалога, если это не противоречит более сильным language rules.

Под explicit project language rules понимаются project rule files и иные явно designated project-level sources of truth для language conventions.

Multi-platform templating policy:
- core workflow logic должна быть platform-agnostic и жить в `templates/`;
- platform-specific behavior должен изолироваться через `platforms/*.env`, placeholders и узкие template adaptations там, где различие реально необходимо;
- generated platform outputs не являются source of truth и не должны редактироваться вручную;
- при добавлении новой платформы нужно расширять template system и platform configuration layer, а не форкать workflow logic;
- platform-specific capabilities, invocation patterns, install targets и ограничения должны описываться как platform layer, а не смешиваться с core workflow design без необходимости.

Build / install / release policy:
- `build`, install flows, release packaging и CI/CD должны быть ориентированы только на новую workflow-first skill system;
- generated outputs и install targets должны приводиться к новой целевой системе без legacy residue;
- additive coexistence старых и новых runtime artifacts не допускается;
- implementation может использовать cleanup, overwrite или иные replacement-oriented механизмы, но итоговое desired state должно содержать только новую систему.

Command UX policy:
- внешний command UX должен использовать новый набор команд проекта, а не legacy naming и не names, заимствованные из Superpowers;
- user-facing commands должны быть короткими, быстро набираемыми, совместимыми с платформами без поддержки дефиса в именах команд и не должны конфликтовать с установленным Superpowers plugin.
- internal stage identifiers могут оставаться техническими внутри реализации, но не должны показываться пользователю в UI, prompts, status updates, reports summaries или handoff text.

Утвержденный command mapping:
- `/cpatrol` — главная точка входа в workflow; запускает новый workflow run, проверяет незавершенные задачи и начинает рабочий поток
- `/cpresume` — продолжить работу по workflow artifact (`workflow.md`, `design.md`, `plan.md`, report)
- `/cpexecute` — выполнить реализацию по готовому `plan.md`
- `/cpreview` — code review
- `/cpfix` — review fixes
- `/cpplanreview` — plan review
- `/cpplanfix` — plan review fixes
- `/cpdocs` — AI docs update
- `/cprules` — project rules update

Эти команды являются целевым внешним UX новой системы:
- implementation не должна сохранять старые command names как равноправный runtime interface;
- platform-specific packaging/install должны публиковать именно этот command surface.

Во всем user-facing описании системы:
- нужно использовать утвержденные command names (`/cpatrol`, `/cpresume`, `/cpexecute`, `/cpreview`, `/cpfix`, `/cpplanreview`, `/cpplanfix`, `/cpdocs`, `/cprules`);
- вместо технических stage IDs нужно использовать понятные display names, например `plan review`, `review fixes`, `AI docs update`, `project rules update`, `execution`;
- старые stage names допустимы только как внутренние технические идентификаторы workflow.

Internal naming policy:
- user-facing command names и internal reusable names должны быть разными слоями;
- user-facing layer использует только утвержденные команды проекта;
- internal skills, agents, prompts и stage identifiers должны использовать English-only technical names;
- внутренние имена должны быть стабильными, descriptive и не обязаны совпадать с user-facing commands;
- implementation не должна светить internal skill/agent names пользователю без явной технической необходимости.

## Общий workflow

Базовый task workflow:

1. `/cpatrol`
2. research
3. clarification
4. approach options
5. итеративное обсуждение solution outline
6. research refresh
7. design
8. plan
9. `/cpplanreview`
10. `/cpplanfix`
11. bounded plan revalidation
12. `/cpexecute`
13. `/cpreview`
14. `/cpfix`
15. final verification
16. `/cpdocs`

Workflow-задача считается завершенной только после `/cpdocs`.

`/cprules` в обязательный task workflow не входит.

## Гранулярность workflow

По умолчанию:
- одна пользовательская задача соответствует одной workflow-задаче;
- одна workflow-задача содержит ровно один design file и один plan file.

Если пользователь явно просит разбить работу на несколько независимых потоков:
- создаются несколько workflow-задач;
- каждая задача получает свою task directory;
- у каждой задачи свой отдельный один design и один plan.

Система не имеет права автоматически дробить одну задачу на несколько workflow tasks. Она может только предложить это пользователю.

## Структура task folder

Постоянная AI-память проекта:

- `.ai/docs/`

Артефакты workflow-задачи:

- `.ai/tasks/<YYYY-MM-DD-HHMM-<task-slug>>/`
  - `<task-slug>.workflow.md`
  - `<task-slug>.design.md`
  - `<task-slug>.plan.md`
  - `reports/`
    - `<REAL-YYYY-MM-DD-HHMM>-<task-slug>.plan-review.report.md`
    - `<REAL-YYYY-MM-DD-HHMM>-<task-slug>.code-review.report.md`

Ad-hoc отчеты, не привязанные к конкретной workflow-задаче:

- `.ai/reports/`
  - `<REAL-YYYY-MM-DD-HHMM>-<scope>.code-review.report.md`
  - другие ручные report-артефакты, если task folder не используется

Правила именования:
- имя папки задачи включает дату-время и task slug;
- файлы `workflow`, `design` и `plan` используют только task slug;
- review reports используют фактическое время создания;
- reports являются накопительными audit-артефактами;
- design и plan правятся итеративно в одном и том же файле.

## Workflow state file

У каждой задачи есть один workflow state file:

- `<task-slug>.workflow.md`

Это центральный state-файл процесса. Он хранит:
- metadata задачи;
- текущую стадию;
- общий статус;
- ссылки на артефакты;
- трекинг стадий;
- ключевые execution-решения;
- минимальные заметки, достаточные для продолжения в новой сессии.

`Overall status` намеренно упрощен:
- `in-progress`
- `done`

Незавершенные или оборванные задачи остаются `in-progress`.

Workflow-файл должен содержать:
- `Task`
- `Status`
- `Artifacts`
- `Stage Tracking`
- `Decisions`
- `Notes`

`workflow.md` должен оставаться на English:
- это рабочий state artifact для агентов, а не project-facing documentation file;
- мультиязычность для него не требуется;
- его schema и служебные поля должны оставаться стабильными между платформами.

Трекинг стадий должен покрывать:
- Research
- Clarification
- Approach options
- Research refresh
- Design
- Plan
- Review plan
- Fix review plan
- Plan revalidation
- Execute
- Review code
- Fix review code
- Update AI docs

Для стадий используются статусы:
- `open`
- `in-progress`
- `done`
- `skipped`

Глобальный verification gate:
- никакая стадия не может быть переведена в `done` без свежего verification evidence;
- никакой handoff не может считаться завершенным без проверки, релевантной его результату;
- никакой finding не может быть переведен в `done` только на основании предположения или факта изменения файла;
- overall workflow status не может стать `done` без подтверждения завершения всех обязательных стадий через релевантные проверки.

Для не-кодовых стадий verification evidence определяется через stage outputs:
- `Research` считается подтвержденным, когда зафиксирован usable research output: summary findings, релевантные sources, facts / assumptions / open questions;
- `Clarification` считается подтвержденной, когда закрыты значимые вопросы либо они явно переведены в assumptions/risks, а рабочий scope и direction определены;
- `Design` считается подтвержденным, когда обновлен единый `design.md` и пользователь утвердил текущий design state или явно разрешил двигаться дальше;
- `Plan` считается подтвержденным, когда обновлен `plan.md` и он прошел plan review, plan review fixes и bounded revalidation.

## Warning о незавершенных задачах

Перед созданием новой workflow-задачи `/cpatrol` обязан проверить `.ai/tasks/` на наличие незавершенных задач.

Если такие задачи есть:
- показать warning;
- перечислить task id, current stage display name и overall status;
- предложить два варианта:
  - продолжить одну из незавершенных задач;
  - проигнорировать warning и создать новую задачу.

Агент не должен молча создавать новую задачу, если уже есть незавершенные workflow-задачи.

## Глобальные правила чтения контекста

Это общее правило для всех навыков, агентов и команд, которым нужен проектный контекст.

Обязательное поведение:
- начинать с `.ai/docs/README.md`;
- по нему находить только релевантные docs-файлы;
- читать только релевантные docs;
- затем читать только релевантные участки кода;
- переходить в дополнительные кодовые файлы только тогда, когда это действительно нужно для текущей задачи.

Запрещенное поведение по умолчанию:
- читать всю документацию подряд;
- читать большие куски репозитория “на всякий случай”;
- обходить все связанные файлы без обоснования текущей задачей.

Если skill/agent не может надежно понять, что ему нужно читать:
- он обязан остановиться;
- объяснить, что именно неясно;
- предложить вероятные варианты;
- спросить пользователя.

Это правило распространяется на:
- `brainstorm`
- `research`
- `design`
- `plan`
- `review-plan`
- `fix-review-plan`
- `executor`
- `review-code`
- `fix-review-code`
- `update-ai-docs`
- `update-project-rules`

## Blocker Policy

Для всего workflow действует единая blocker policy.

Базовый decision principle внутри этой policy:
- infer when safe;
- ask when ambiguous;
- не гадать молча, если intent, scope или target неясны.

Blocker’ом считается ситуация, в которой дальнейшее движение вперед уже нельзя считать надежным или безопасным без дополнительного решения, данных или вмешательства.

Типовые blocker-ситуации:
- критический разрыв или противоречие между `design`, `plan`, code, rules или repo state;
- неоднозначность intent или выбора, влияющего на смысл реализации;
- отсутствие нужного инструмента, доступа, dependency или входных данных;
- повторяющийся провал verification, review или revalidation после разумных попыток исправления;
- конфликт между findings, subagents или execution assumptions, который нельзя надежно разрешить автоматически.

Поведение при blocker’е:
- остановить текущее продвижение по стадии;
- не проталкивать workflow дальше “на авось”;
- зафиксировать суть blocker’а в workflow/report context, если это уместно для текущей стадии;
- кратко объяснить, что именно блокирует продолжение;
- если возможно, предложить разумные варианты следующего шага;
- спросить пользователя только там, где safe inference уже недостаточен.

Blocker policy особенно обязательна для:
- `executor`
- `review-plan`
- `fix-review-plan`
- `review-code`
- `fix-review-code`
- `update-ai-docs`

## `/cpatrol`

`/cpatrol` — это user-facing умная точка входа в workflow.

Он должен:
- сначала проверять незавершенные задачи;
- создавать task folder и workflow file для нового workflow run;
- запускать project research до дизайна и плана;
- внутри себя классифицировать сложность задачи;
- задавать пользователю только реально незакрытые вопросы;
- предлагать альтернативные подходы, если есть несколько реалистичных вариантов;
- поддерживать несколько итераций по solution outline;
- предлагать перейти к созданию дизайна только тогда, когда research и обсуждение уже достаточны.

Внутренняя entry stage внутри `/cpatrol` сама выбирает глубину процесса по задаче, но не имеет права сама дробить одну задачу на несколько workflow tasks без явного запроса пользователя.

Адаптивность означает:
- для небольшой задачи workflow может быть минимально достаточным;
- для средней и большой задачи должен использоваться полный контур;
- стадии нельзя пропускать произвольно, без опоры на research, scope и риски задачи.

Если пользователь запускает `/cpatrol` с неполным или неидеально сформулированным запросом:
- система должна сначала попытаться сама вывести intent и scope из доступного контекста;
- если один вариант явно доминирует, его можно использовать как рабочее предположение;
- если есть несколько реалистичных трактовок или риск ошибки значим, нужно остановиться и спросить пользователя;
- при уточнении нужно предлагать варианты, а не задавать расплывчатый вопрос.

## Research

`research` — первая содержательная стадия.

Он собирает контекст из четырех источников:
- project memory в `.ai/docs/`;
- текущих task artifacts, если они релевантны;
- реального состояния репозитория;
- agent/project rules;
- внешних материалов по задаче, которые дал пользователь.

Он обязан:
- начинать с `.ai/docs/README.md`;
- быть обязательной и формализованной стадией внутри `/cpatrol`, а не неявным просмотром контекста;
- при необходимости сверять задокументированные паттерны с реальным кодом;
- собирать только релевантный контекст;
- отличать факты, assumptions и открытые вопросы;
- выявлять пробелы в информации;
- готовить короткий список уточняющих вопросов.

На выходе `research` должен формировать:
- что уже известно по задаче;
- что подтверждено кодом, docs и rules;
- какие паттерны проекта релевантны;
- каких данных не хватает;
- какие вопросы нужно задать пользователю;
- какие части системы, скорее всего, будут затронуты.

`.ai/docs` является обязательным слоем долговременной project memory:
- `research` внутри `/cpatrol` обязан начинать с `.ai/docs/README.md`;
- затем читать только релевантные `domains/` и `shared/` docs;
- и только потом переходить к task artifacts и коду;
- решения и ограничения, зафиксированные в `.ai/docs`, должны учитываться при research, clarification, выборе подхода, design и plan.

Он не должен:
- преждевременно уходить в проектирование решения;
- трактовать неподтвержденные догадки как факт;
- игнорировать `AGENTS.md`, `CLAUDE.md` или локальные rule files.

## Clarification и Approach Options

После research:
- workflow обязан задать вопросы по недостающей информации;
- обсуждать только реально незакрытые места;
- показывать варианты решения, если существует несколько жизнеспособных подходов.

Сравнение вариантов должно включать:
- краткое описание подхода;
- какие части системы он затрагивает;
- trade-offs;
- сложность;
- риски;
- рекомендуемый вариант.

Если реальных альтернатив нет:
- агент должен прямо сказать, что практический путь по сути один;
- он не должен выдумывать искусственные варианты ради формального соблюдения этапа.

Пользователь может несколько раз дорабатывать solution outline до перехода к design.

После выбора направления:
- `/cpatrol` сначала формирует solution outline;
- пользователь может несколько раз скорректировать scope, подход, ограничения или запросить дополнительные варианты;
- после каждого такого цикла агент обязан обновить outline, показать изменения и, при необходимости, обновить trade-offs;
- только после подтверждения solution outline предлагается переходить к формированию design.

## Research Refresh

Перед генерацией дизайна выполняется короткий `research refresh`.

Он обязателен после:
- initial research;
- clarification;
- обсуждения вариантов;
- выбора направления;
- итераций по solution outline.

Он должен:
- перепроверить выбранный подход по кодовой базе;
- подтвердить финальный scope;
- еще раз проверить конфликты с docs и project rules;
- добрать детали, которые стали важны только после выбора подхода.

Это не полный повтор `research`, а целевой re-sync перед дизайном.

## Design

На одну workflow-задачу приходится один design file:

- `<task-slug>.design.md`

Этот файл правится итеративно в процессе обсуждения.

Design file хранится внутри task folder:
- `.ai/tasks/<task-id>/<task-slug>.design.md`

Он является артефактом конкретного workflow run и связан с:
- `<task-slug>.workflow.md`
- `<task-slug>.plan.md`
- task-scoped review reports

Отдельные design versions внутри одного workflow run не создаются:
- все итерации правятся в этом же файле;
- второй независимый design в рамках той же задачи не создается;
- если пользователь хочет два независимых design/plan потока, это уже две разные workflow-задачи.

Design file должен быть единственным артефактом, который пользователь читает и утверждает перед переходом к плану.

Design file должен включать:
- цель задачи;
- summary результатов research;
- ограничения и релевантные rules;
- рассмотренные подходы;
- выбранный подход и объяснение выбора;
- solution outline;
- impact analysis;
- assumptions и открытые вопросы;
- диаграммы, если они реально помогают.

Дефолтный формат дизайна:
- Markdown
- Mermaid

Полезные типы диаграмм по умолчанию:
- DFD
- Sequence
- диаграммы связей и зависимостей модулей

Для design допустимо использовать C4/C4-lite, если это помогает, но это не жесткое обязательство на каждую задачу.

Приоритет формата документации и диаграмм:
1. project rules и уже принятые в проекте conventions
2. явная инструкция пользователя для конкретной задачи
3. дефолт workflow:
   - Markdown
   - Mermaid
   - DFD
   - Sequence
   - module relationship diagrams

## Роль Design

Роль:
- senior software architect

Обязан:
- проектировать на основе research и реального устройства проекта, а не “идеальной архитектуры в вакууме”;
- учитывать ограничения и контекст проекта;
- явно показывать trade-offs;
- выдавать один цельный design artifact на утверждение.

Не должен:
- переходить к плану или реализации;
- придумывать неуместную архитектурную сложность;
- молча игнорировать project rules.

## Plan

На одну workflow-задачу приходится один plan file:

- `<task-slug>.plan.md`

План правится итеративно в том же файле после review/fix.

Plan file хранится внутри task folder:
- `.ai/tasks/<task-id>/<task-slug>.plan.md`

Он является task-scoped артефактом и связан с:
- `<task-slug>.workflow.md`
- `<task-slug>.design.md`
- review reports в `reports/`

План должен быть компактным, но execution-ready и пригодным для оркестраторного исполнения.

План хранит delivery intent и execution contract, а не максимальную пошаговую детализацию.

Plan writer обязан заранее учитывать:
- утвержденный design;
- `.ai/docs/README.md` и релевантные docs;
- project rules;
- реальный код, если он нужен для уточнения плана;
- execution strategy;
- execution model;
- commit strategy;
- тесты, если они применимы;
- docs updates, включая `.ai/docs`;
- обновление обычной проектной документации, если это нужно;
- API/documentation systems, такие как Swagger/OpenAPI, JSDoc, JavaDoc и аналоги, если они реально используются в проекте.

Результат plan writer рассматривается как draft for mandatory review:
- следующий обязательный шаг после записи плана — `/cpplanreview`;
- затем `/cpplanfix`;
- затем bounded revalidation;
- только после этого plan считается execution-ready.

Если design и `.ai/docs`/project rules расходятся:
- plan writer не должен молча выбирать одну сторону;
- это должно быть либо вынесено обратно в discussion, либо как минимум поймано на стадии plan review.

План должен быть пригоден не только для человека, но и для orchestration:
- исполнитель может запускаться в текущей сессии или в новой;
- реализация может идти через subagents или agent team;
- plan должен быть достаточно структурирован, чтобы executor мог разбить работу на independent units, определить checkpoints и safe parallelization;
- при этом plan не должен разрастаться до подробной execution matrix.

Перед написанием плана workflow обязан уточнить commit strategy у пользователя.

Commit strategy должна быть определена до написания плана и влияет на:
- структуру stages;
- checkpoints;
- execution safety;
- возможное распараллеливание;
- rollback safety.

Поддерживаемые стратегии коммитов:
- без промежуточных коммитов;
- коммит по stage;
- коммит по step;
- кастомная стратегия под конкретную задачу.

## Header плана

В шапке плана должны быть:
- ссылка на design file;
- ссылка на plan file;
- task slug;
- время создания;
- goal;
- scope;
- execution mode;
- execution model;
- recommended skills;
- recommended agents/subagents;
- high-level parallelization strategy;
- commit strategy;
- constraints;
- verification and documentation strategy.

`Execution model` обязателен:
- по умолчанию это current model;
- при необходимости можно явно указать более слабую модель;
- если указана более слабая модель, plan writer обязан адаптировать гранулярность плана под нее.

## Тело плана

Тело плана остается намеренно компактным.

Оно должно содержать:
- stages;
- objective каждого stage;
- key steps;
- verification;
- ожидания по commit.

План не обязан содержать:
- полный код;
- пошаговый TDD на каждый микрошаг;
- детальный список файлов для каждого микродействия;
- точные shell-команды для каждого действия.

Подробную execution topology на уровне каждого шага в plan вносить не нужно. Это задача executor.

То есть:
- plan defines delivery structure;
- executor defines execution structure.

Plan writer должен описывать stages, key steps, checkpoints, commit expectations, verification и documentation obligations,
но не обязан расписывать:
- точного исполнителя на каждый шаг;
- микрозависимости между каждым действием;
- per-step context slicing;
- полную parallelization matrix.

Если коммиты нужны:
- в плане должно быть явно указано, где они ожидаются и к каким checkpoints относятся.

Если коммиты не нужны:
- это тоже должно быть явно отражено в плане, а не оставлено неявным.

## Роль Plan Writer

Роль:
- senior technical lead / delivery architect

Обязан:
- превращать утвержденный дизайн в исполнимый план;
- сохранять план компактным, но применимым;
- включать тестовые и документационные обязательства там, где они нужны;
- учитывать commit strategy и execution model;
- поддерживать один обновляемый plan file на workflow-задачу.

Не должен:
- молча менять смысл design;
- подменять планирование новым архитектурным проектированием;
- пропускать тесты, docs и verification, если они релевантны.

## `/cpplanreview`

`/cpplanreview` — user-facing команда для запуска специализированного reviewer’а плана.

Он обязан проверять:
- соответствие `AGENTS.md`, `CLAUDE.md` и локальным rule files;
- согласованность header и body плана;
- полноту stages и verification;
- test coverage, если в проекте есть тесты и они релевантны;
- docs updates, если изменение затрагивает документацию;
- соответствие утвержденному design;
- исполнимость плана для указанной execution model;
- можно ли улучшить план так, чтобы уменьшить контекст на исполнителя или безопасно улучшить распараллеливание.

Он обязан различать:
- `auto-fix`
- `ask-user`
- `accept-as-is`

Если plan отличается от design:
- reviewer обязан определить, это ошибка, допустимая эволюция или спорное отклонение;
- если он не может решить это надежно, он обязан спросить пользователя.

## Plan Review Reports

Отчеты по review плана для workflow-задачи сохраняются всегда:
- `reports/<REAL-YYYY-MM-DD-HHMM>-<task-slug>.plan-review.report.md`

Даже внутри flow они создаются, но пользователю не обязательно показывать их полностью без необходимости.

В ручном режиме review плана:
- report тоже сохраняется;
- пользователь может читать его напрямую.

Каждый finding в report содержит:
- severity;
- recommended resolution;
- status;
- resolved via;
- resolution notes.

Допустимые статусы:
- `open`
- `done`
- `skipped`

Finding не может переводиться в `done` без свежего evidence, подтверждающего, что соответствующая проблема действительно устранена или больше не актуальна.

## `/cpplanfix`

`/cpplanfix` обрабатывает findings из review плана.

Он обязан:
- работать только с `open` findings;
- автоматически применять безопасные и однозначные fixes;
- спрашивать пользователя там, где есть несколько допустимых вариантов или меняется intent;
- обновлять tracking-поля в review report;
- править тот же один plan file.

Он может распараллеливать независимые фиксы, но только если они действительно независимы.

После фиксов:
- выполняется bounded revalidation;
- нельзя уходить в бесконечный цикл;
- если revalidation находит крупные или неоднозначные новые проблемы, нужно остановиться и спросить пользователя.

## Checkpoint “Plan Ready”

Когда план готов:
- plan уже должен пройти `/cpplanreview`, `/cpplanfix` и bounded revalidation;
- workflow обновляет `workflow.md`;
- workflow оценивает, хватает ли контекста для продолжения реализации в текущей сессии;
- если контекста, вероятно, достаточно, пользователю предлагается выбор:
  - выполнять в текущей сессии;
  - выполнять в новой сессии.
- если контекста, вероятно, недостаточно, workflow рекомендует новую сессию, но окончательный выбор остается за пользователем.

Для новой сессии handoff command должна быть короткой:
- она должна ссылаться на конкретный task artifact path;
- wording должен следовать active user-facing language policy;
- если language policy явно не задана, fallback wording — English.

Executor обязан уметь понять остальной контекст из плана и task artifacts.

`Plan ready` не означает автоматический немедленный старт реализации:
- plan review подтверждает корректность и полноту плана как execution contract;
- фактическую готовность к старту в текущем состоянии репозитория проверяет `executor` в самом начале своей работы;
- если между review плана и стартом исполнения состояние репозитория изменилось, именно `executor` обязан это заметить и остановить небезопасный запуск.

`/cpatrol` ведет процесс как минимум до состояния `plan ready`, а не заканчивается сразу после первой записи плана.

Выбор между текущей и новой сессией после `plan ready` является частью общего UX-паттерна workflow:
- тот же паттерн повторяется позже перед `/cpreview` и, при необходимости, перед `/cpdocs`;
- plan writer и `/cpatrol` должны формировать артефакты так, чтобы короткий handoff в новую сессию был достаточным.

Общая эвристика выбора режима:
- текущая сессия предпочтительна, если контекста явно хватает, задача достаточно компактна, trade-offs уже закрыты и выгоден плотный интерактивный цикл;
- новая сессия предпочтительна, если task artifacts уже самодостаточны, предстоящая работа длинная или многостадийная, ожидаются checkpoints и текущий контекст уже тяжелый;
- workflow должен не просто давать выбор, а формировать обоснованную рекомендацию;
- окончательный выбор обычно остается за пользователем, если риск потери качества не стал явно высоким.

## `/cpexecute`

`/cpexecute` — user-facing команда запуска реализации по готовому плану.
Она поднимает нужный контекст из `plan.md` и связанных task artifacts и запускает execution orchestration.

Execution orchestration — это orchestration-style слой реализации.

Это не просто линейный кодер. Его задача:
- читать план как execution contract;
- строить execution topology;
- минимизировать контекст на implementer subagents;
- решать, что можно безопасно параллелить;
- решать, когда нужно спросить пользователя из-за trade-offs.

Execution orchestrator является центральным orchestration layer реализации:
- сначала он строит execution graph и execution strategy;
- сначала выполняет короткий preflight по актуальности и исполнимости плана в текущем состоянии репозитория;
- только потом запускает implementers;
- он ближе к дирижеру исполнения, чем к обычному linear execution skill.

## Роль Execution Orchestrator

Роль:
- senior execution architect / implementation orchestrator

Умеет:
- читать plan и design;
- строить execution graph из stages и key steps;
- выводить зависимости и зоны для параллельного выполнения;
- выдавать subagents только минимально необходимый контекст;
- выбирать execution strategy исходя из plan header и реального состояния проекта.

Обязан:
- начать с executor preflight;
- перед стартом проверить plan на актуальность относительно репозитория;
- построить execution strategy до начала реализации;
- предпочитать минимально достаточный контекст, если это не снижает качество;
- соблюдать commit strategy, project rules и verification requirements;
- спрашивать пользователя, если есть несколько осмысленных execution strategies;
- после реализации передавать работу в `/cpreview`.

Не должен:
- молча менять design или смысл плана;
- переусердствовать с параллельностью в конфликтующих зонах;
- запускать исполнение по устаревшему или противоречивому plan без явной фиксации проблемы.

`executor preflight` должен проверять:
- что plan действительно находится в состоянии execution-ready после `review-plan`, `fix-review-plan` и bounded `revalidation`;
- что task artifacts (`workflow`, `design`, `plan`, task-scoped reports) согласованы между собой;
- что текущее состояние репозитория не противоречит критическим предпосылкам плана;
- что execution strategy и commit strategy все еще применимы;
- что выбранный способ изоляции исполнения достаточен для текущей задачи.

Branch safety rule внутри `executor preflight`:
- если реализация должна стартовать в основной защищенной ветке проекта, executor обязан остановиться и запросить явное подтверждение пользователя;
- без такого подтверждения implementation start запрещен;
- основной защищенной веткой считаются `main`, `master` или иная branch, явно определенная project rules / repo conventions;
- это правило защищает от случайного запуска реализации в небезопасном git-контексте, но не навязывает единственную стратегию изоляции.

Граница ответственности между `review-plan` и `executor`:
- `review-plan` отвечает за корректность, полноту и исполнимость плана как артефакта;
- `executor preflight` отвечает за проверку, что этот план все еще безопасно и разумно запускать прямо сейчас.

## Runtime flow Executor

1. Plan intake
2. Executor preflight
3. Чтение design и релевантных rules
4. Проверка plan относительно текущего состояния репозитория
5. Построение execution graph
6. Выбор execution strategy
7. Вопрос пользователю только если trade-offs действительно значимы
8. Dispatch implementation work
9. Stage checkpoints
10. Handoff в `/cpreview`

Checkpoint reporting discipline внутри `executor`:
- на каждом значимом checkpoint executor должен кратко фиксировать, какой stage или checkpoint завершен;
- он должен показывать, что реально было изменено или достигнуто;
- он должен опираться на релевантный verification evidence, а не только на описание проделанной работы;
- он должен явно отмечать blockers, новые risks и открытые trade-offs, если они появились;
- он должен принимать решение, можно ли безопасно продолжать автоматически или нужен pause.

## Контракт implementer subagent

Каждый implementing subagent обязан:
- соблюдать project rules, style, архитектурные ограничения и forbidden patterns;
- работать только в пределах своего scope;
- выполнять локальный self-check перед handoff;
- при необходимости проверять ближайший impact от своих изменений;
- запускать релевантные lint/tests/checks, доступные в проекте;
- локально чинить очевидные проблемы в своей зоне ответственности;
- эскалировать конфликт между планом, кодом и rules в executor.

## Acceptance и Verification

Проверки происходят на трех уровнях:

1. ожидаемый impact, заложенный в plan;
2. implementer self-check;
3. executor acceptance-check и stage-level verification.

Executor не должен полностью дублировать проверки implementer’а.

Implementer:
- отвечает за локальную корректность и ближайший impact.

Executor:
- проверяет, что шаг или stage соответствует плану;
- проверяет, что нужные проверки действительно были выполнены;
- проверяет собранный stage как рабочую единицу.

После каждого значимого stage или checkpoint executor должен выполнить checkpoint reporting pass:
- краткий progress summary;
- verification evidence по текущему результату;
- blockers / risks / open trade-offs;
- решение: продолжать автоматически, остановиться для user feedback или рекомендовать handoff в новую сессию.

После каждого stage, либо после группы параллельных stage’ов в общем checkpoint, executor обязан прогнать все релевантные project checks:
- линтеры;
- форматтеры или статические проверки;
- тесты;
- build/typecheck, если применимо;
- другие обязательные проверки из project rules.

Если проверки падают:
- executor сначала пытается исправить проблему и повторить прогон;
- при необходимости может попробовать альтернативный корректный способ запуска инструментов;
- спрашивает пользователя только если разумные попытки не помогли или ситуация стала неоднозначной.

Repeated verification failure должен рассматриваться как blocker:
- executor не должен бесконечно повторять циклы исправления и проверки;
- после разумного числа корректных попыток он обязан остановиться и эскалировать проблему.

Автоматическое продолжение после checkpoint допустимо только если:
- текущий checkpoint подтвержден релевантными проверками;
- не появились новые значимые trade-offs;
- следующий шаг остается low-risk и не требует явного пользовательского решения.

Pause на checkpoint обязателен, если:
- завершен крупный stage;
- завершена группа параллельных работ;
- изменился risk profile;
- дальнейший шаг существенно меняет тип работы;
- появился смысл рекомендовать handoff в новую сессию.

Verification в этом workflow является не просто шагом, а обязательным gate:
- stage, checkpoint или handoff нельзя объявлять завершенным без свежих результатов релевантной проверки;
- изменение кода, плана или docs само по себе не является доказательством завершенности;
- любое утверждение о готовности должно опираться на evidence, относящееся к текущему состоянию артефактов.

## `/cpreview`

`/cpreview` — user-facing команда orchestration-style review кода.

Внутри code review есть два обязательных логических слоя:
- `compliance pass`
- `quality pass`

Порядок обязателен:
- сначала проверяется, соответствует ли реализация утвержденным intent, design, plan и project rules;
- только потом выполняется углубленный review инженерного качества.

Он должен поддерживать:
- автоматический review после execution;
- ручной review для:
  - current working tree;
  - staged changes;
  - diff текущей ветки;
  - diff branch-vs-branch;
  - PR/MR;
  - всего проекта.

## Роль Review Code

Роль:
- senior principal reviewer / review orchestrator

Обязан:
- определять или уточнять review scope;
- выполнять review planning pass;
- начинать с обязательного `compliance pass`;
- решать, остается ли review однопроходным или его стоит разнести по нескольким reviewer agents;
- учитывать project docs, rules и задокументированные accepted constraints;
- собирать findings в единый нормализованный результат.

`Compliance pass` проверяет:
- соответствует ли реализация `design`;
- соответствует ли реализация `plan`;
- соблюдены ли project rules и documented constraints;
- нет ли scope creep;
- не пропущены ли обязательные части задачи.

`Quality pass` проверяет:
- архитектурное и кодовое качество реализации;
- adequacy тестов и verification;
- maintainability, reliability, security и performance risks, если они релевантны;
- читаемость, локальную чистоту исполнения и отсутствие неуместной сложности.

Гибридная модель выполнения review:
- для простых и хорошо очерченных задач orchestrator может выполнить `compliance pass` сам;
- для средних и сложных задач orchestrator может выделить отдельного `compliance reviewer` subagent;
- после `compliance pass` orchestrator запускает quality-oriented reviewer agents по нужным измерениям, например архитектура, тесты, security, conventions.

Не должен:
- репортить как обычный defect то, что в проекте уже зафиксировано как допустимое ограничение;
- делать широкий шумный review без нормального scoping;
- считать любое отклонение от plan/design ошибкой без оценки контекста.

## Research rules для Review Code

Перед review:
- начинать с `.ai/docs/README.md`;
- читать только релевантные domain/shared docs;
- читать task artifacts, если review task-scoped;
- выявлять documented exceptions, accepted trade-offs и ограничения;
- только потом читать релевантный код.

Для `compliance pass` обязательными источниками являются:
- `workflow.md`, если review идет в рамках workflow-задачи;
- утвержденный `design`;
- актуальный `plan`;
- релевантные project rules и accepted constraints.

## Review Code Reports

Code review reports по workflow-задаче сохраняются всегда:
- `reports/<REAL-YYYY-MM-DD-HHMM>-<task-slug>.code-review.report.md`

Ad-hoc code review reports сохраняются в:
- `.ai/reports/`

Формат finding’ов такой же, как у plan review:
- severity;
- finding type;
- recommended resolution;
- status;
- resolved via;
- resolution notes.

Code review finding не может переводиться в `done` без проверки, подтверждающей, что риск действительно устранен, либо без явной фиксации, почему finding больше не применим.

`Finding type` должен различать как минимум:
- `compliance`
- `quality`

Это различие нужно, чтобы `fix-review-code` исправлял сначала отклонения от intent и обязательных требований, а затем улучшал инженерное качество.

## `/cpfix`

`/cpfix` — user-facing команда code-fix orchestration.

Он обязан:
- обрабатывать только `open` findings;
- по умолчанию приоритизировать `compliance` findings перед `quality` findings;
- перед стартом определять fix policy;
- если policy не задана, спросить пользователя;
- поддерживать:
  - выбор по severity: critical / critical+important / all
  - выбор по стилю обработки: manual per item / auto simple ask complex / custom free-form policy
- распараллеливать только независимые fixes;
- обновлять tracking-поля в review report;
- выполнять bounded revalidation;
- после фиксов обязательно выполнять финальный прогон всех релевантных project checks;
- обновлять workflow state внутри task flow.

Переход к `quality` findings должен происходить:
- после устранения отклонений от intent, design, plan и обязательных rules;
- либо только тогда, когда объединенная правка явно безопасна, локально связана с `compliance` fix и не ухудшает traceability review loop.

Если `fix-review-code` сталкивается с конфликтующими findings, неясной fix policy или повторяющимся провалом revalidation, это считается blocker и требует остановки вместо принудительного продолжения.

Финальный verification pass обязателен и должен включать все доступные и релевантные проверки:
- lint;
- tests;
- build/typecheck, если применимо;
- другие обязательные project checks.

Bounded revalidation после `fix-review-code` должна сначала подтверждать, что `compliance`-риски действительно закрыты, и только затем считать цикл исправления готовым к окончательному закрытию quality-related findings.

После успешного завершения `/cpfix` и финального verification code path считается завершенным, но вся workflow-задача еще не считается завершенной:
- следующим обязательным решением является handoff в `/cpdocs` или перенос этого шага в новую сессию;
- cleanup execution environment не может происходить автоматически только потому, что кодовая часть уже подтверждена.

## Handoff между execution и review

После завершения `/cpexecute` execution orchestrator не должен молча запускать review.

Он обязан предложить:
- review в текущей сессии;
- review в новой сессии.

Для новой сессии используется короткая команда. Review-часть должна уметь поднять контекст из task artifacts.

При выборе режима review применяется общий session-mode heuristic.
Для review особенно важно учитывать, не станет ли отделение review от execution context более безопасным и более читаемым вариантом.

## Completion и Cleanup Policy

В workflow нужно явно различать:
- `code path complete`
- `workflow complete`

`Code path complete` означает:
- `/cpexecute` завершен;
- code review и fix cycle завершены;
- финальный verification pass по коду успешно пройден;
- кодовая часть готова к переходу в documentation/update phase.

`Workflow complete` означает:
- завершен `code path`;
- завершен `/cpdocs`;
- workflow state обновлен;
- выполнены все обязательные проверки и закрыты обязательные findings.

После завершения кодовой части workflow обязан явно принять completion decision:
- продолжать `/cpdocs` в текущей сессии;
- перенести `/cpdocs` в новую сессию;
- сохранить execution environment для последующего merge, PR, follow-up review или ручной проверки;
- отложить cleanup до явного подтверждения, если дальнейший post-code flow еще не закрыт.

Silent cleanup запрещен:
- нельзя автоматически удалять или закрывать branch/worktree/другое execution environment только по факту успешной реализации кода;
- нельзя считать cleanup безопасным, если он может помешать review, docs update, merge или follow-up work;
- cleanup допустим только как явное решение с учетом следующего шага workflow.

## Структура AI Docs

Постоянная AI-документация живет в:
- `.ai/docs/`

Структура:
- `.ai/docs/README.md`
- `.ai/docs/domains/`
- `.ai/docs/shared/`

`README.md` — обязательная точка входа для всех context-aware агентов.

`domains/` хранит стабильную документацию по конкретным областям системы.

`shared/` хранит стабильную документацию по общим темам, например:
- тестирование;
- деплой;
- API contracts;
- dependency maps;
- conventions;
- observability;
- auth-модели;
- другие сквозные архитектурные темы.

## Формат AI Docs

Дефолтный формат `.ai/docs`:
- Markdown
- Mermaid

Полезные типы диаграмм по умолчанию:
- DFD
- Sequence
- module relationship diagrams

Для `.ai/docs` C4-lite является дефолтным подходом к структурированию, когда это действительно помогает, но не обязательным жестким стандартом для каждого файла.

Каждый docs-файл должен быть AI-friendly:
- ясная цель;
- когда его читать;
- scope;
- related docs;
- key modules/components;
- relationships;
- constraints and rules;
- change impact;
- source of truth references.

Документация должна быть рассчитана на targeted reading, а не на чтение всего подряд.

## README для AI Docs

`.ai/docs/README.md` обязателен.

Он должен:
- объяснять, какие docs существуют;
- объяснять, что покрывает каждый docs-файл;
- объяснять, когда читать какой файл;
- маршрутизировать к relevant domain/shared docs;
- позволять research-агентам не читать всю документацию целиком.

## `/cpdocs`

`/cpdocs` — user-facing команда documentation orchestration.

Он может работать в режимах:
- task workflow mode;
- whole-project mode;
- scoped mode;
- check mode или update mode для ручных запусков.

Он должен понимать ручные intents, например:
- “проверить текущую документацию”
- “обнови документацию для незакоммиченного кода”
- “проверь документацию между ветками”

Если он не может надежно понять intent или scope:
- он обязан спросить пользователя и предложить варианты.

## Роль AI Docs Orchestrator

Роль:
- AI project memory maintainer / documentation orchestrator

Обязан:
- начинать с `.ai/docs/README.md`;
- выбирать только релевантные docs;
- читать только релевантные task artifacts и код;
- документировать только устойчивое и финальное знание;
- поддерживать навигацию через README;
- делать docs модульными и пригодными для следующих агентов;
- использовать дефолт Markdown + Mermaid, если project rules не требуют иного;
- обновлять `workflow.md`, если он работает внутри task flow.

Не должен:
- читать всю `.ai/docs/` и весь код по умолчанию;
- переносить в `.ai/docs` временные рассуждения по задаче;
- документировать assumptions как факты;
- ломать README-based navigation.

## Runtime flow AI Docs Orchestrator

1. Определить intent и scope
2. Решить, продолжать ли в текущей сессии или лучше перенести в новую
3. Запустить docs research от `.ai/docs/README.md`
4. Прочитать релевантные task artifacts и финальное состояние кода
5. Спланировать обновления документации
6. Внести изменения в docs
7. Выполнить docs validation pass
8. Обновить workflow state

## Эвристика по сессии для docs update

Система должна оценивать, стоит ли продолжать `/cpdocs` в текущей сессии или лучше вынести его в новую.

Здесь применяется общий session-mode heuristic.

Если платформа показывает остаток контекста, нужно использовать его.
Если нет, нужно оценивать остаток эвристически по объему уже накопленного контекста и сложности следующего шага.

Handoff command для новой сессии должна оставаться короткой и ссылаться на конкретный workflow artifact path.
Ее wording должен следовать active user-facing language policy, а при отсутствии явного language rule fallback language — English.

Если `/cpdocs` переносится в новую сессию:
- workflow должен зафиксировать, что кодовая часть завершена;
- execution environment должен сохраняться как минимум до тех пор, пока не станет ясно, нужен ли он для review, merge или follow-up действий;
- cleanup не должен происходить автоматически при handoff.

Для `/cpdocs` тоже применяется общий выбор режима:
- текущая сессия подходит, если релевантный контекст еще свежий, scope документации ограничен и изменение безопасно для продолжения без дополнительного context reset;
- новая сессия предпочтительна, если кодовая часть уже накопила много контекста, docs update крупный или нужен более чистый documentation-focused run.

Если `/cpdocs` не может надежно определить documentation scope, source of truth или обнаруживает конфликт между кодом, task artifacts и существующей `.ai/docs`, он обязан применить blocker policy, а не продолжать на предположениях.

## Docs Validation Pass

Внутри `/cpdocs` финальная validation должна проверять:
- что структура `.ai/docs` осталась понятной;
- что `README.md` актуален и продолжает работать как навигатор;
- что новые файлы включены в навигацию;
- что `domains/` и `shared/` использованы логично;
- что docs соответствуют финальному коду и итогу task flow;
- что документация по-прежнему пригодна для targeted reading.

Сейчас это внутренний шаг `/cpdocs`, а не отдельная стадия workflow.

`/cpdocs` не может считаться завершенным только по факту редактирования файлов документации:
- завершенность этой стадии подтверждается только после docs validation pass;
- обновление workflow status без этой проверки запрещено.

## Правило завершения workflow

Workflow-задача считается завершенной только если завершены все обязательные стадии, включая:
- design, если он был нужен;
- plan и его review/fix/revalidation;
- execution;
- review/fix кода;
- финальную verification;
- `/cpdocs`.

`/cprules` в завершенность task workflow не входит.

Финальный перевод workflow-задачи в `done` допускается только после прохождения глобального verification gate:
- все обязательные стадии должны быть реально подтверждены релевантными проверками;
- все обязательные findings должны быть либо закрыты с evidence, либо явно зафиксированы как `skipped` с объяснением;
- состояние workflow не должно опираться на неактуальные или предположительные результаты проверок.

Финальное завершение workflow не должно неявно подменять собой operational cleanup:
- статус `done` означает завершенность обязательного workflow;
- дальнейшие действия уровня merge, PR, branch retention или cleanup должны быть либо уже явно решены, либо явно оставлены как post-workflow decision;
- workflow не должен молча удалять execution environment в момент перевода задачи в `done`.

## `/cprules`

`/cprules` — отдельная ручная user-facing команда.

Он не входит в обязательный workflow задачи.

Его задача:
- анализировать завершенные задачи и review reports;
- находить повторяющиеся findings и fix patterns;
- определять недостающие, слабые, устаревшие или неэффективные project rules;
- объяснять, почему существующее правило не сработало, если такое правило уже есть;
- предлагать улучшения;
- после подтверждения пользователя применять выбранные изменения к правилам проекта.

Он работает в две фазы:

1. анализ и предложения прямо в чате
2. selective apply после решения пользователя

Пользователь может:
- принять все;
- принять отдельные пункты;
- дать свободный текст с тем, как именно нужно поменять правило.

После этого инструмент должен:
- обновить существующие rule files;
- либо создать новые sections/files, если это действительно нужно.

Он не должен:
- менять project rules без подтверждения пользователя;
- превращать разовую проблему в новое правило без достаточных оснований;
- добавлять бюрократию ради бюрократии.

## Итог

Этот workflow-дизайн намеренно построен на следующих принципах:
- одна умная точка входа;
- компактный внешний command UX;
- специализированные внутренние стадии;
- постоянный workflow state;
- audit-friendly review reports;
- контекстно-экономное чтение через `.ai/docs/README.md`;
- один design и один plan на одну workflow-задачу;
- явный контроль пользователя там, где intent или trade-offs неоднозначны.

Система спроектирована так, чтобы одинаково хорошо жить в Codex и Claude за счет того, что:
- состояние workflow хранится в артефактах репозитория;
- логика живет в stage-specific skills и агентах;
- платформенно-специфичное поведение ограничено вызовом и установкой.
