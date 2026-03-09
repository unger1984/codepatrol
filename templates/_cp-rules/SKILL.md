---
name: cp-rules
description: Improve project rules based on workflow reports, recurring patterns, or user request
---

# /cp-rules

Analyze evidence and improve project rules.

## Progress Tracking (mandatory)

Before starting work, you MUST create {{PROGRESS_TOOL}} items for each runtime step.
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

{{@platform-include:rules-authoring}}

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
1. Read existing project rules from `{{RULES_SOURCE}}`
2. Check for duplicates — is this topic already covered?
3. Draft a rule based on the user's description — the user's request is the primary input, not codebase analysis
4. Present as a proposal (see Output Format) with placement recommendation
5. Apply after user approval

**Direct mode:** when the user provides the exact rule text:
1. Read existing project rules from `{{RULES_SOURCE}}`
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

1. Clarify which rules the user expected to apply — if unclear from context, ask with concrete options (list existing rule files, recent review reports). Use `{{ASK_USER}}` if available.
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

Always ask — never silently pick an option. Use `{{ASK_USER}}` if available, otherwise ask in chat.

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
- rules from `{{RULES_SOURCE}}`
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

{{DISPATCH_RESEARCHER}}

**Researcher prompt:**

{{@include:_shared/researcher.md}}

**Query construction:** include the topic or focus area, and request the researcher to:
- read current project rules from `{{RULES_SOURCE}}` and understand what is already covered
- analyze relevant codebase areas for patterns, conventions, inconsistencies
- return: current rules summary, observed patterns, gaps, conflicts, and recommendations with evidence

## Subagent Model Policy

{{@include:_shared/model-policy.md}}

{{@include:_shared/subagent-limits.md}}

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

After presenting proposals, ask the user which to apply. Use `{{ASK_USER}}` if available. Accept any of these response forms:
- "apply all" → apply all proposals
- "apply #1, #3, #5" → apply only the listed numbers
- "apply all except #2" → apply everything except the listed numbers
- "skip all" → apply nothing, complete without changes

After applying, summarize: which proposals were applied, which files were changed, which proposals were skipped.

## Blocker Policy

Stop and ask the user when:
- a proposal conflicts with another existing rule
- the evidence is ambiguous and multiple rule interpretations are valid
- the scope of a rule change is broader than the evidence supports

Do not push rules on guesses. Infer when safe, ask when ambiguous.

When asking the user, use `{{ASK_USER}}` if available on the current platform.

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
