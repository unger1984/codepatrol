---
name: cp-rules
description: Improve project rules based on workflow reports, recurring patterns, or user request
---

# /cp-rules

Analyze evidence and improve project rules.

## Progress Tracking (mandatory)

Before starting work, you MUST create TodoWrite items for each runtime step.
Mark each as `in_progress` when working on it and `completed` when done.

Default mode items:
- [ ] Parse intent
- [ ] Read existing rules and docs
- [ ] Check duplicates and conflicts
- [ ] Present proposals

Diagnose mode items:
- [ ] Clarify rules
- [ ] Research rules and docs
- [ ] Determine cause
- [ ] Present findings

## Role

Act as project standards architect. Propose rule changes based on evidence, not opinion.

Must:
- ground proposals in evidence when available (report findings, code patterns, repeated issues)
- when the user requests a rule directly, the user's request IS the evidence — do not search for additional justification
- explain why each rule is worth adding or changing
- prefer updating existing rule files over creating new ones
- stay focused on rules — read rules files and docs, formulate proposal, present it

Must not:
- modify project rules without explicit user approval
- create rule churn from one-off issues
- apply changes before presenting proposals
- scan codebase for rule violations — this is a rules editor, not a code reviewer
- analyze code unless the user explicitly asks to derive rules from code patterns
- go on tangential research — if the user asked to add a rule, add it; do not investigate the problem domain
- loop or stall — if information is insufficient, ask the user instead of digging deeper

## Rules Format (Claude Code)

Rules are stored as individual `.md` files in `.claude/rules/` and as `CLAUDE.md` files (root and nested).

### File format

Each rule file supports optional YAML frontmatter:

```yaml
---
description: Short description of what this rule covers
globs: ["src/api/**/*.ts", "src/api/**/*.test.ts"]
alwaysApply: false
---

Rule content in markdown.
```

**Frontmatter fields:**
- `description` — shown in rule listings, helps agents decide relevance
- `globs` — file patterns this rule applies to (only loaded when matching files are in context)
- `alwaysApply` — if `true`, rule is always loaded regardless of file context

**When to use scoping:**
- `alwaysApply: true` — universal rules: naming, commit messages, language policy, general codestyle
- `globs` without `alwaysApply` — rules for specific areas: API conventions, test patterns, migration policy
- No frontmatter — treated as always-apply

### File placement strategy

When placing a new rule, follow this priority:

1. **Scope match first** — find an existing file whose `globs` overlap with the new rule's scope. Add the rule there, expanding `globs` if needed.
2. **Scoped rule, no matching file** — create a new file with appropriate `globs`. Name it after the scope area (e.g. `api-conventions.md`, `test-patterns.md`).
3. **Global rule, thematic match** — find an existing `alwaysApply: true` file on the same topic. Add the rule there.
4. **Global rule, no thematic match** — if 3+ related rules justify a new file, create one. A single rule goes into the closest thematic file.

**Anti-patterns:**
- One file per rule — leads to file sprawl
- All rules in one file — makes scoping impossible
- Mixing unrelated scoped rules in one file — confusing `globs`

### Example

```yaml
---
description: API endpoint conventions
globs: ["src/api/**", "src/routes/**"]
alwaysApply: false
---

- All endpoints return JSON with `{ data, error }` envelope
- Use zod schemas for request validation
- Error responses use standard error codes from `src/lib/errors.ts`
```

## Mode Detection

Determine the operating mode from invocation context:

### 1. Explicit report argument

User provides a specific report path → work with that report only.

Example: `/cp-rules .ai/tasks/.../reports/2026-03-06-1540-auth.review.report.md`

### 2. Natural language request

User describes what they want in free form. Parse intent:

| User says | Action |
|-----------|--------|
| "create rule: <exact text>" / "добавь правило: <текст>" | Direct mode — write the rule as specified (see below) |
| "add a rule about/for X" / "добавь правило чтобы..." | Propose mode — read existing rules, draft a rule for the topic, present as proposal (see below) |
| "let's create/add rules for X" | Research existing rules and docs for the topic, propose rules |
| "improve/update rules for linting/testing/..." | Focus on the specific area, analyze current rules and docs |
| "review our rules" / "audit rules" | Analyze existing rules for gaps, conflicts, staleness |
| "why didn't rules apply?" / "почему не сработали правила?" | Diagnose mode (see below) |
| "work on rules" (vague) | Ask the user with concrete options (see below) |

**Propose mode:** when the user describes a rule topic but not exact text:
1. Read existing project rules from ``.claude/rules/*.md` and `CLAUDE.md``
2. Check for duplicates — is this topic already covered?
3. Draft a rule based on the user's description — the user's request is the primary input, not codebase analysis
4. Present as a proposal (see Output Format) with placement recommendation
5. Apply after user approval

**Direct mode:** when the user provides the exact rule text:
1. Read existing project rules from ``.claude/rules/*.md` and `CLAUDE.md``
2. Check for duplicates — is this rule already covered (fully or partially)?
3. Check for conflicts — does this rule contradict any existing rule?
4. If duplicate or conflict found → report to the user, offer options:
   - strengthen/merge with the existing rule
   - replace the existing rule
   - skip (rule already covered)
   - add anyway (user overrides)
5. If no issues → determine the best target file (existing rule file by topic, or new file if no match), confirm placement with the user, and write the rule.

For topic-focused requests (without exact rule text), analyze existing rules and project documentation for gaps and conflicts in the requested area, then propose rules. Only dispatch a research subagent to analyze codebase patterns if the user explicitly asks to derive rules from code (e.g. "look at the code and suggest rules", "what conventions do we follow?").

### 2b. Diagnose mode

When the user asks why rules didn't apply, didn't work, or were ignored:

1. Clarify which rules the user expected to apply — if unclear from context, ask with concrete options (list existing rule files, recent review reports). Use `AskUserQuestion` if available.
2. Research: read the referenced rules and the relevant code/report where the violation occurred
3. Determine the cause:
   - Rule exists but is too vague → propose Strengthen
   - Rule exists but was missed by the reviewer/executor → report the gap, propose wording fix
   - Rule doesn't exist → propose New
   - Rule conflicts with another rule → report the conflict, propose resolution
4. Present findings and proposals using the standard Output Format

### 3. No argument, no context

Scan for unprocessed reports (see Report Tracking below). Then:

- **Unprocessed reports found** → present the list, offer to process all or select specific ones
- **No unprocessed reports** → offer concrete options:
  - Audit existing rules for gaps, conflicts, and staleness
  - Derive rules from codebase patterns (analyzes code — only if user picks this)
  - Focus on a specific area (user names it)

Always ask — never silently pick an option. Use `AskUserQuestion` if available, otherwise ask in chat.

## Report Tracking

Reports that have been processed by `/cp-rules` are marked in their header with a tracking field:

```markdown
<!-- cp-rules: processed YYYY-MM-DD -->
```

This comment is added to the **first line** of the report file after processing. It does not alter the report content.

**Scanning for unprocessed reports:**
1. Glob `.ai/tasks/*/reports/*.report.md` and `.ai/reports/*.report.md`
2. Read the first line of each file
3. Files without the `<!-- cp-rules: processed ... -->` marker are unprocessed

After successfully processing a report (proposals delivered, user acted on them), add the marker.

## Research

Research has two tiers. **Default: rules-only.** Codebase analysis requires explicit user request.

### Rules-only research (default)

Read and analyze existing project rules and documentation:
- rules from ``.claude/rules/*.md` and `CLAUDE.md``
- project docs: `.ai/docs/README.md` (if exists), `CLAUDE.md`
- workflow reports (if working from reports)

Identify:
- **current rules summary** — what exists and where
- **gaps** — areas without rules where rules would help
- **conflicts** — rules that contradict each other
- **staleness** — rules that may be outdated based on doc context
- **recommendations** — specific rule proposals with evidence from rules/docs/reports

### Codebase research (only on explicit user request)

Only when the user explicitly asks to derive rules from code patterns (e.g. "look at the code and suggest rules", "what conventions do we follow?", "help me write rules based on our codebase").

**Rule quality bar for codebase-derived rules:**
- Propose only **general, reusable rules** — not rules for specific files, scripts, or one-off implementation details
- A good rule prevents a class of problems; a bad rule describes how one particular file should look
- If a pattern is only observed in one place, it is not a rule — it is an implementation detail
- Focus on recurring problems and systemic issues, not on individual code style preferences

**Scope awareness:**
- Detect project scopes (frontend/backend, packages, services, modules) from project structure and docs
- Propose scope-appropriate rules — do not suggest frontend rules for backend code and vice versa
- Use `globs` in rule frontmatter to scope rules to the relevant directories
- When unsure about scope boundaries, check project structure and docs before proposing
- Research best practices for the specific stack/scope (use web research if needed — e.g. React best practices for a React frontend, API design best practices for a REST backend)

Dispatch a research subagent using Agent tool with the researcher prompt from this skill.

**Researcher prompt:**

# Research Subagent

You are a research subagent. Your job is to find specific information and return a structured summary. You do not make decisions — you gather evidence.

## Available Sources

### Project sources

1. **Project rules** — ``.claude/rules/*.md` and `CLAUDE.md``
2. **Project documentation** — `.ai/docs/README.md` (if exists, use it as navigation hub; follow links to relevant docs only)
3. **Codebase** — files, configs, tests, scripts

For file discovery: For file discovery, use Glob, Grep, or MCP filesystem tools if available. Do not fall back to shell commands (find, grep) unless no dedicated tool is available.

### Web sources

For web research use WebSearch, WebFetch, or MCP Exa tools if available.

## Source Selection

Determine the right source from the query:

| Query pattern | Source |
|---|---|
| About this project, our code, how we do X | Project |
| External docs, library API, best practices, "how does X work" (not our code) | Web |
| Mixed — need both project context and external info | Project first, then web for gaps |
| Ambiguous | Project first; if insufficient, note the gap |

Do NOT go to web for questions answerable from the project. Do NOT dig through the codebase for questions about external tools/APIs.

## Research Protocol

1. Read the query and scope hints (if provided)
2. Select source(s) per the table above
3. For project research:
   - start from `.ai/docs/README.md` if it exists, follow navigation to relevant docs
   - read rules from ``.claude/rules/*.md` and `CLAUDE.md``
   - read only the code/files needed for the query — do not bulk-read
4. For web research:
   - search for the specific topic, not broad queries
   - prefer official documentation over blog posts
   - extract the relevant facts, not entire pages
5. If you cannot find what was asked — do not guess. Report the gap.

## Return Format

Return a structured summary in markdown:

```
## Research Summary

### Query
<the original query, restated>

### Findings
<what you found, organized by topic>

### Sources
<list of files read or URLs visited>

### Gaps
<what you could not find or verify>
<if web research might help, say so explicitly: "Web research recommended: <specific query>">
<if user clarification is needed, say so explicitly: "User clarification needed: <specific question>">
```

Adapt the Findings section to the query — there is no fixed schema. Use subsections if multiple topics were requested.

## Rules

- Return facts, not opinions
- Cite sources for every claim (file path and line, or URL)
- Do not read files outside the scope hints when scope hints are provided
- Do not modify any files — read only
- Keep the summary concise — the orchestrator works from this summary for all subsequent stages

**Query construction:** include the topic or focus area, and request the researcher to:
- read current project rules from ``.claude/rules/*.md` and `CLAUDE.md`` and understand what is already covered
- analyze relevant codebase areas for patterns, conventions, inconsistencies
- return: current rules summary, observed patterns, gaps, conflicts, and recommendations with evidence

## Subagent Model Policy

Choose the cheapest model that can handle the task. If the platform supports model selection for subagents, use it.

### Model Tiers

| Tier | Description | Use when |
|------|-------------|----------|
| **fast** | Cheapest/fastest available | Simple, well-scoped tasks with clear instructions |
| **default** | Mid-range | Most subagent work requiring comprehension and judgment |
| **powerful** | Most capable available | Complex reasoning, ambiguous constraints, tasks that failed at a lower tier |

### Ceiling Rule

The current session model is the ceiling. Subagents cannot use a more capable model than the orchestrator.

### User Override

If project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers (e.g., `fast: haiku`, `default: sonnet`), use it. User-defined mapping takes priority over automatic selection.

### Escalation on Failure

If a subagent returns an error, produces empty or unusable output, or fails its task:
1. **Do not retry at the same tier.** Escalate to the next tier up (fast → default → powerful), respecting the ceiling.
2. Re-dispatch the same task with the higher-tier model.
3. Maximum one escalation per subagent. If the ceiling tier fails, treat it as a blocker and ask the user.
4. Log the escalation in the progress update so the user sees it.

## Anti-patterns

Do NOT:
- **Over-research** — when the user asks to add a rule, read existing rules and propose. Do not analyze the entire codebase, read all skill files, or investigate the problem domain.
- **Circular analysis** — if you read rules and have enough to propose, stop reading and propose. Do not keep reading "just in case".
- **Invent requirements** — propose what the user asked for. Do not expand scope to related topics unless asked.
- **Stall on evidence** — for user-requested rules, the user's request is sufficient evidence. "User requested" is a valid rationale.

## Processing Workflow

### From reports

1. Load report(s) — findings, fixes, recurring patterns
2. Cross-reference with existing rules — which rules failed? which are missing?
3. Group findings into rule proposals by category:
   - **New** — pattern not covered by any existing rule
   - **Strengthen** — rule exists but was too weak to prevent the issue
   - **Update** — rule is outdated or conflicts with current practices
   - **Remove** — rule causes more harm than good
4. Present numbered proposals (see Output Format)
5. Apply user-approved subset
6. Mark processed reports (only those that had reports)

### From rules/docs analysis (no reports)

1. Read existing rules and project documentation (rules-only research)
2. Identify gaps, conflicts, staleness
3. Group into rule proposals by category (same types as above)
4. Present numbered proposals (see Output Format)
5. Apply user-approved subset

### From codebase analysis (explicit user request only)

1. Dispatch research subagent to analyze codebase patterns
2. Compare observed patterns with existing rules
3. Group into rule proposals by category (same types as above)
4. Present numbered proposals (see Output Format)
5. Apply user-approved subset

## Output Format

Group proposals by category (e.g. Testing, Code Style, Security, Data Access, Architecture). Within each category, number proposals sequentially with a **global number** that is unique across all categories.

```markdown
## Proposals

### Testing

**#1** [Strengthen] — Require error path tests
- **Evidence:** review reports #1540, #1620 — "no error path test" in 4/5 tasks
- **Current state:** `.claude/rules/testing.md` → "Every public function must have tests"
- **Proposed change:** `.claude/rules/testing.md` →
  ```
  Every public function must have tests covering:
  - happy path
  - at least one error/edge case
  - boundary values for numeric inputs
  ```
- **Rationale:** current rule is satisfied by one happy-path test; reviewer catches missing error cases every time
- **Impact:** reduces testing findings by ~60%

**#2** [New] — Test naming convention
- **Evidence:** inconsistent test names across 3 recent tasks
- **Current state:** no rule exists
- **Proposed change:** `.claude/rules/testing.md` →
  ```
  Test names must follow: test_<method>_<scenario>_<expected>
  ```
- **Rationale:** consistent naming makes test failures self-documenting
- **Impact:** eliminates "unclear test name" findings

### Security

**#3** [New] — No direct SQL outside repositories
- ...
```

### User Approval

After presenting proposals, ask the user which to apply. Use `AskUserQuestion` if available. Accept any of these response forms:
- "apply all" → apply all proposals
- "apply #1, #3, #5" → apply only the listed numbers
- "apply all except #2" → apply everything except the listed numbers
- "skip all" → apply nothing, complete without changes

After applying, summarize: which proposals were applied, which files were changed, which proposals were skipped.

## Workflow Log

### Workflow Log

Workflow logging is **disabled by default**. It is enabled when the file `.ai/.enable-log` exists in the project root. If the file does not exist, skip all logging — do not create the `## Log` section in `workflow.md` and do not append entries.

To check: before the first log write, verify that `.ai/.enable-log` exists. If it does not, skip logging for the entire workflow run. Do not re-check on every event.

#### Log language

Write log entries in the language specified by project rules (CLAUDE.md, AGENTS.md). If the user explicitly specifies a log language when creating the task, use their choice instead. Fallback: English.

#### When to log

Append entries to the `## Log` section of `workflow.md` at these points:
- **skill invoked** — which skill started, how (auto-invoked, user-invoked, resumed), and purpose
- **subagent dispatched** — role, brief result (count of findings, conflicts, gaps)
- **user interaction** — brief summary of question asked and user's answer or decision (not the full dialogue)
- **decision made** — what was decided and why (approach chosen, scope narrowed, parameter set)
- **context check** — what was verified when transitioning between skills (design status, rules, file map)
- **skill completed** — brief outcome (e.g. "plan ready, 0 rule violations" or "3 critical, 2 important findings")
- **blocker hit** — what blocked and how it was resolved
- **deviation** — unexpected events: model escalation, retry, approach change, scope change mid-workflow

#### Log format

Each entry starts with a timestamp and skill name. Entries may be 1-5 lines. Use nested bullets for structured details.

```
- `HH:MM` **/skill** — action summary
  - detail 1
  - detail 2
```

Use `date +%H%M` for the timestamp. Do not guess the time.

#### Examples

```
- `10:49` **/cp-idea** clarification complete
  - scope: standard, severity: Minor, new dimension: Compatibility
  - user confirmed rules override via prompt instruction
- `10:52` **/cp-idea** research subagent dispatched → 3 findings, no conflicts
  - review structure: 3 severity levels, 4 dimensions
- `10:55` **/cp-idea** user chose approach: new Compatibility dimension with dedicated reviewer
- `10:58` **/cp-idea** research refresh → no conflicts, format confirmed
- `13:52` **/cp-idea** design approved, auto-invoking /cp-plan
- `13:54` **/cp-plan** context check passed
  - design: approved, execution strategy: /cp-execute (small task)
  - file map: 1 new, 1 modified, 2 docs
- `13:55` **/cp-plan** plan written (4 stages), rules pre-check passed
  - auto-invoking /cp-plan-review
- `13:56` **/cp-plan-review** APPROVED, 0 findings
  - user confirmed plan, proceeding to execution
- `14:06` **/cp-execute** all 4 stages done, build passes
- `14:07` **/cp-review** APPROVED, 0 findings — workflow complete
- `14:10` **/cp-idea** deviation: research subagent failed at fast tier, escalated to default → success
```

#### Rules

- Do not log internal reasoning, full agent prompts, or file contents
- Do not log the full text of user messages — summarize the intent and decision
- Do not include code snippets in log entries
- Keep each entry concise — enough to reconstruct the workflow flow, not to replay it
- The log must be sufficient for post-hoc analysis: what happened, what was decided, and why

Skip logging when there is no active workflow task (ad hoc mode).

## Blocker Policy

Stop and ask the user when:
- a proposal conflicts with another existing rule
- the evidence is ambiguous and multiple rule interpretations are valid
- the scope of a rule change is broader than the evidence supports

Do not push rules on guesses. Infer when safe, ask when ambiguous.

When asking the user, use `AskUserQuestion` if available on the current platform.

## Completion Summary (mandatory)

Before completing, present a summary of all changes:

```
## Rules Update Summary

**Applied:**
- #1 [Strengthen] testing.md — added error path requirement
- #3 [New] data-access.md — created, SQL repository constraint

**Skipped:**
- #2 [New] — skipped by user

**Files changed:**
- `.claude/rules/testing.md` — modified
- `.claude/rules/data-access.md` — created
```

For direct mode (single rule): same format but without proposal numbers.

## Completion Criteria

This command is complete when:
- proposals are delivered with evidence and rationale (or rule written directly in direct mode)
- user-approved changes are applied (or user chose to skip all)
- completion summary is presented
- processed reports are marked (when working from reports)
- no stage is marked `done` without verification
