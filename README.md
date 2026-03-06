**English** | [Русский](README.ru.md)

# CodePatrol

Workflow-first skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Codex CLI](https://github.com/openai/codex). CodePatrol replaces the old review-only interaction with a full lifecycle workflow that keeps templates in `templates/` and platform differences in `platforms/*.env`.

## Inspiration

CodePatrol was inspired by [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent — a pioneering skill-based workflow for coding agents. Superpowers showed that agents work dramatically better when guided by composable skills rather than ad-hoc prompts.

CodePatrol takes this idea further by adding structured artifact storage, session resumability, compliance-first reviews, and a full task lifecycle with audit trail.

## CodePatrol vs Superpowers

| Area | Superpowers | CodePatrol |
|------|------------|------------|
| **Approach** | Composable general-purpose skills that trigger automatically | Full lifecycle workflow with structured stages and handoffs |
| **Artifact storage** | No persistent structure — context lives in chat | `.ai/` directory: `workflow.md`, `design.md`, `plan.md`, reports |
| **Session resumability** | Start over in new session | `/cpresume` restores exact stage from artifacts |
| **Code review** | Single-pass review against plan | Two-pass: compliance first (design/plan/rules), then quality (arch/security/tests/conventions) |
| **Review execution** | Single reviewer | Parallel specialized reviewers (architecture, security, testing, conventions) |
| **Fix tracking** | Manual | Incremental report mutation — each finding tracked with status, resolution, and evidence |
| **Plan validation** | No dedicated step | `/cpplanreview` → `/cpplanfix` cycle before implementation |
| **Documentation** | No dedicated step | `/cpdocs` — AI-oriented docs in `.ai/docs/` with navigation and validation |
| **Rule evolution** | No dedicated step | `/cprules` — proposes project rule improvements from accumulated findings |
| **Ad hoc mode** | N/A | Any review/fix command works outside workflow tasks |
| **Audit trail** | No | Append-only reports, workflow.md decision history |
| **Platform support** | Claude Code, Codex, Cursor, OpenCode | Claude Code, Codex CLI |

Both projects are MIT-licensed. They can coexist — Superpowers covers general development discipline (TDD, worktrees, brainstorming), while CodePatrol focuses on the structured task lifecycle with artifacts, reviews, and audit trail.

## Table of Contents

- [Quick Start](#quick-start)
- [Inspiration](#inspiration)
- [CodePatrol vs Superpowers](#codepatrol-vs-superpowers)
- [What CodePatrol Solves](#what-codepatrol-solves)
- [Workflow Overview](#workflow-overview)
- [Data Storage And Organization](#data-storage-and-organization)
- [How To Run](#how-to-run)
- [Session Example](#session-example)
- [Install](#install)
- [Rules And Context](#rules-and-context)
- [Development](#development)
- [CI/CD](#cicd)
- [Known Limitations](#known-limitations)

## Quick Start

**Requirements:** [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [Codex CLI](https://github.com/openai/codex) installed.

```bash
# 1. Install skills
curl -fsSL https://raw.githubusercontent.com/unger1984/codepatrol/main/install-remote.sh | bash

# 2. Open your project in Claude Code
cd your-project

# 3. Start your first task
/cpatrol add caching to the API layer
```

CodePatrol will create `.ai/` in your project, run research, discuss the approach, and prepare a design + plan. The workflow will guide you to the next command from there.

## What CodePatrol Solves

- **Unified workflow surface:** One command set controls research, design, planning, execution, reviews, fixes, docs, and rule updates, hiding internal stage IDs from users.
- **Context-aware agents:** Every command begins from `.ai/docs/README.md` and workflow artifacts so agents only read what matters.
- **Audit-friendly artifacts:** `.ai/tasks/` tracks `<slug>.workflow.md`, `<slug>.design.md`, `<slug>.plan.md`, and review reports; fixes mutate only documented tracking fields.

## Workflow Overview

```mermaid
---
title: Task Workflow
---
flowchart LR
    subgraph design ["🔍 Design"]
        direction TB
        cpatrol("/cpatrol")
        research["research\nclarification\napproach options"]
        des["design.md"]
        plan["plan.md"]
        cpatrol --> research --> des --> plan
    end

    subgraph plancheck ["📋 Plan Review"]
        direction TB
        planreview("/cpplanreview")
        planfix("/cpplanfix")
        planreview -- "findings" --> planfix
        planfix -. "revalidation" .-> planreview
    end

    subgraph impl ["⚡ Implementation"]
        direction TB
        execute("/cpexecute")
        checkpoints["checkpoint reports\nstep verification"]
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

    subgraph docs ["📚 Documentation"]
        cpdocs("/cpdocs")
    end

    design -- "plan.md" --> plancheck
    plancheck -- "approved plan" --> impl
    impl -- "handoff" --> review
    review -- "verified" --> docs
    docs --> done([✅ Task complete])
```

```mermaid
---
title: Data Flow and Artifacts
---
flowchart TD
    subgraph storage [".ai/"]
        subgraph docsdir [".ai/docs/"]
            readme[("README.md\nnavigator")]
            domains["domains/\nshared/"]
        end
        subgraph taskdir [".ai/tasks/‹timestamp›-‹slug›/"]
            workflow["workflow.md\nstate + stages"]
            designf["design.md"]
            planf["plan.md"]
            reports["reports/\nplan-review · code-review"]
        end
        adhoc[".ai/reports/\nad-hoc reports"]
    end

    cpatrol2("/cpatrol") -- "creates" --> workflow
    cpatrol2 -- "creates" --> designf
    cpatrol2 -- "creates" --> planf
    planreview2("/cpplanreview") -- "writes" --> reports
    cpfix2("/cpfix") -- "updates tracking" --> reports
    cpreview2("/cpreview") -- "writes" --> reports
    cpreview2 -- "ad-hoc mode" --> adhoc
    cpdocs2("/cpdocs") -- "updates" --> docsdir
    cpresume2("/cpresume") -. "reads" .-> workflow
    cpresume2 -. "reads" .-> reports

    readme -. "entry point\nfor all commands" .-> cpatrol2
    readme -. "entry point\nfor all commands" .-> cpreview2
```

```mermaid
---
title: Utility Commands
---
flowchart LR
    interrupted([Interrupted session]) --> cpresume("/cpresume")
    cpresume -- "detects stage\nfrom workflow.md" --> resume_target(["→ continues at correct step"])

    experience([Accumulated experience]) --> cprules("/cprules")
    cprules -- "analyzes reports\nand findings" --> proposals["rule change\nproposals"]
    proposals -- "after approval" --> rules[(".claude/rules/\nCLAUDE.md\nAGENTS.md")]
```

## Data Storage And Organization

CodePatrol creates an `.ai/` directory in the project that serves two purposes: long-term project memory and current task artifacts.

### `.ai/docs/` — Project Memory

Persistent AI-oriented documentation. This is not a duplicate of regular docs but a separate knowledge layer optimized for agents: architectural decisions, project patterns, domain-specific constraints.

`README.md` inside is the mandatory entry point. Every CodePatrol command starts context discovery from it, follows navigation to find relevant docs, and reads only what is needed. This prevents aimless repository scanning.

Created and updated by `/cpdocs` based on completed task results.

### `.ai/tasks/` — Task Artifacts

Each workflow task lives in its own directory: `.ai/tasks/<YYYY-MM-DD-HHMM>-<slug>/`.

Inside are three core files created by `/cpatrol` and updated by subsequent commands:

- **`<slug>.workflow.md`** — central state file. Tracks the current stage, status, artifact references, stage completion, and key decisions. This is what `/cpresume` uses to determine where to continue.
- **`<slug>.design.md`** — solution design. Produced during `/cpatrol` after research and approach discussion. One per task, edited iteratively.
- **`<slug>.plan.md`** — implementation plan. One per task, must pass `/cpplanreview` before execution.

Tasks also contain `reports/` — plan review and code review reports. Reports are audit artifacts: `/cpplanfix` and `/cpfix` update only tracking fields (status, resolution method, notes) but never delete or rewrite findings.

### `.ai/reports/` — Ad-hoc Reports

Reports outside workflow tasks. For example, `/cpreview` for an arbitrary branch or PR saves results here rather than in a task directory.

### Why This Matters

- **Resumability.** A task can be continued in a new session via `/cpresume` — all context lives in artifacts, not chat memory.
- **Audit trail.** Decision history and findings are preserved — reports are append-only, workflow.md captures key decision points.
- **Context isolation.** Agents read `.ai/docs/README.md` → relevant docs → task artifacts → code. No bulk repository scanning.

## How To Run

Commands are entered in Claude Code or Codex CLI. Each command auto-discovers relevant artifacts from `.ai/tasks/` and `.ai/docs/`. If context is ambiguous, the command will ask.

### Full Task Workflow

The workflow is organized around a single task: one task = one design + one plan. A task is considered complete only after AI documentation is updated.

**1. Start — `/cpatrol`**

Single entry point. Checks for unfinished tasks and offers to resume them or start a new one. For a new task it runs a mandatory chain:
- **research** — gather context from `.ai/docs/`, code, and project rules;
- **clarification** — resolve ambiguities with the user;
- **approach options** — compare approaches with trade-offs and a recommendation;
- **design** — produce `design.md`;
- **plan** — produce `plan.md`.

Process depth adapts to the task: minimal for small fixes, full for large features.

**2. Plan review — `/cpplanreview` → `/cpplanfix`**

Before implementation the plan is checked against the design, project rules, and execution readiness. `/cpplanreview` saves a report with findings, `/cpplanfix` resolves them and runs bounded revalidation.

**3. Implementation — `/cpexecute`**

Executes the approved plan step by step with checkpoint reports. Stops on blockers instead of guessing. On completion it offers to proceed to code review — in the current session or hand off to a new one.

**4. Code review — `/cpreview` → `/cpfix`**

`/cpreview` runs compliance first (design, plan, and rules alignment), then quality (architecture, style, tests, security). The report is saved as `.review.report.md`. `/cpfix` resolves findings in priority order: compliance first, then quality.

**5. Documentation — `/cpdocs`**

Updates AI-oriented documentation in `.ai/docs/` based on the task results. Runs a validation pass: checks navigation, placement, and code alignment.

### Utility Commands

- `/cpresume` — continue an unfinished task. Loads artifacts, detects the current stage, and shows what to do next.
- `/cprules` — not part of the mandatory workflow. Analyzes accumulated results (reports, recurring findings) and proposes project rule improvements. Changes are applied only after user approval.

### Notes

- Any command accepts an explicit artifact path: `/cpresume .ai/tasks/2026-03-06-1420-my-task/`.
- `/cpreview` also works outside the workflow — you can review a branch, PR, directory, or file set.
- When a command asks “which artifact?”, answer with a path or a short form: `current task`, `new task`.

## Session Example

```
> /cpatrol add rate limiting for the API

🔍 Research: reading .ai/docs/README.md → docs/domains/api.md → src/api/...
Found: Express + Redis, 12 endpoints, JWT authentication.

❓ Clarification:
  1. Same limits for all endpoints or split by group?
  2. Store counters in Redis (already in project) or in-memory?
  → Recommendation: Redis + different limits for auth vs data endpoints.

> 1 — by group, 2 — Redis, agree with recommendation

📐 Design: created .ai/tasks/2026-03-06-1420-rate-limiting/rate-limiting.design.md
📋 Plan: created rate-limiting.plan.md (3 stages, 8 steps)
   Next step → /cpplanreview

> /cpplanreview

✅ Findings: 1 minor (no fallback when Redis is unavailable)
   Next step → /cpplanfix

> /cpplanfix

🔧 Fixed: added in-memory counter fallback.
   Revalidation passed. Next step → /cpexecute

> /cpexecute

⚡ Stage 1/3: middleware created, tests passing
⚡ Stage 2/3: limit config by group, integration tests ok
⚡ Stage 3/3: documentation updated
   Implementation complete. Next step → /cpreview

> /cpreview

📝 Compliance: ok (matches design and plan)
📝 Quality: 1 important (middleware does not log rejected requests)
   Report: .ai/tasks/.../reports/...-rate-limiting.review.report.md
   Next step → /cpfix

> /cpfix

🔧 Added logging. Verification passed.
   Next step → /cpdocs

> /cpdocs

📚 Updated .ai/docs/domains/api.md (added rate limiting section)
   Task complete.
```

## Install

### Latest release

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

### From source

```bash
git clone https://github.com/unger1984/codepatrol.git
cd codepatrol
./install.sh claude
./install.sh codex
```

The installer removes legacy review skill directories from the target location and installs only the current workflow commands.

## Rules And Context

### Where Project Rules Come From

CodePatrol does not introduce its own rules format — it uses what the platform already provides:

| Platform | Rule sources |
|----------|-------------|
| Claude Code | `.claude/rules/*.md`, `CLAUDE.md` |
| Codex CLI | `AGENTS.md` |

Commands like `/cpreview`, `/cpplanreview`, and `/cpexecute` automatically read project rules and apply them during reviews, plan validation, and implementation. `/cprules` analyzes accumulated results and proposes rule additions or updates.

### Language Policy

CodePatrol automatically adapts language to the project:

1. **Project rules** — if `CLAUDE.md` or `AGENTS.md` specifies a language (e.g., "Responses in Russian"), all artifacts (`design.md`, `plan.md`, reports, `.ai/docs/`) and user-facing output will use that language.
2. **Client language** — if project rules don't specify a language, the agent or client language setting is used.
3. **Fallback** — if no language is specified anywhere, artifacts are created in English.

Exception: `workflow.md` is always kept in English — it is a state file for agents, not documentation.

### Context And `.ai/docs/`

All commands start context discovery from `.ai/docs/README.md` and follow its navigation to find relevant docs. This prevents agents from scanning the entire repository "just in case" and ensures stable behavior even in large codebases.

## Development

```text
templates/                        source-of-truth skill templates
platforms/                        platform-specific placeholder values
skills/                           generated output from ./install.sh build
.claude-plugin/                   Claude marketplace manifests
install.sh                        local build and install entrypoint
install-remote.sh                 release installer
```

```bash
./install.sh build
./install.sh claude
./install.sh codex
```

## CI/CD

CI rebuilds `skills/`, checks that generated output is current, validates placeholder substitution, and verifies the expected `cpatrol` / `cp*` runtime structure for release assets.

## Known Limitations

- Verified primarily on macOS.
- Cursor support is not implemented yet.

## License

MIT
