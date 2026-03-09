# Review System

## Purpose

Documents the code review architecture — two-pass model, specialized reviewers, report format, and fix tracking.

## When to read

- Running or configuring code review (`/cp-review`)
- Fixing findings (`/cp-fix`)
- Understanding report format
- Adding a new reviewer specialization

## Scope

Covers `cp-review` mechanics, reviewer agents, report structure, and `cp-fix` tracking.

## Related docs

- [Skills Reference](skills-reference.md) — all skills overview

---

## Two-Pass Review Model

```mermaid
flowchart TD
    CODE[Code changes] --> P1["Pass 1: Compliance"]
    P1 --> P2["Pass 2: Quality"]
    P2 --> REPORT[Review Report]
    REPORT --> DECIDE{Findings?}
    DECIDE -->|NEEDS_CHANGES| FIX["/cp-fix"]
    DECIDE -->|APPROVED| DONE[Done]
    DECIDE -->|APPROVED_WITH_NOTES| DONE
```

### Pass 1 — Compliance (mandatory first)

Checks adherence to:
- Approved design (`design.md` from `.ai/tasks/`, if exists)
- Implementation plan (`plan.md` from `.ai/tasks/`, if exists)
- Project rules (`.claude/rules/`, `CLAUDE.md` / `AGENTS.md`)

### Pass 2 — Quality

Five review dimensions, each with optional specialized reviewer:

| Dimension | Reviewer file | Subagent tier |
|-----------|--------------|---------------|
| Architecture | `architecture-reviewer.md` | default |
| Security | `security-reviewer.md` | default |
| Testing | `testing-reviewer.md` | default |
| Conventions | `codestyle-reviewer.md` | fast |
| Compatibility | `compatibility-reviewer.md` | fast |

## Execution Models

| Scope | Strategy |
|-------|----------|
| Simple (few files) | Orchestrator handles both passes |
| Medium/Large | Dispatch specialized subagent reviewers in parallel (Claude) or sequentially (Codex) |

Compliance pass always uses **powerful** tier (most critical check).

## Specialized Reviewers

### Architecture Reviewer

- Module boundaries and single responsibility
- Dependency direction (no circular dependencies)
- Layering rules
- Composition over inheritance
- Dead code removal
- Plan compliance

### Security Reviewer

- Injection prevention (SQL, command, path traversal)
- Secrets and sensitive data exposure
- Input validation
- Authorization and IDOR
- Error handling (no sensitive data in errors)
- Concurrency safety

### Testing Reviewer

- Test coverage for new/changed code
- Test quality and edge cases
- Test isolation

### Codestyle Reviewer

- Naming conventions
- Code formatting
- Project style consistency

### Compatibility Reviewer

- Deprecated API usage (libraries, frameworks, language standard library)
- Version compatibility (APIs match declared dependency versions)
- Breaking changes awareness (no reliance on undocumented/internal APIs)
- Default severity: Minor; escalate to Important/Critical based on removal timeline
- Project rules can whitelist specific deprecated APIs or disable the check entirely

## Report Format

```markdown
## Code Review Report

### Summary
- Scope: N files
- Critical: N | Important: N | Minor: N
- Assessment: NEEDS_CHANGES | APPROVED | APPROVED_WITH_NOTES

### Critical Issues
1. [CATEGORY] `file:line` — description
   **Finding type:** compliance | quality
   **Fix:** concrete solution
   **Status:** open | resolved | skipped
   **Resolved via:** (filled after fix)
   **Resolution notes:** (filled after fix)
```

### Severity Levels

| Level | Meaning |
|-------|---------|
| Critical | Must fix before merge — correctness, security, compliance violation |
| Important | Should fix — architecture, maintainability concerns |
| Minor | Nice to fix — style, minor improvements |

### Assessment Values

| Assessment | Meaning |
|------------|---------|
| `NEEDS_CHANGES` | Has critical or open compliance findings |
| `APPROVED_WITH_NOTES` | Only important/minor quality findings |
| `APPROVED` | No findings |

## Fix Tracking (cp-fix)

### Processing Order

Strictly in report order — do not reorder by type or group. The review already places findings in the correct processing order.

### Incremental Report Mutation

After each finding is processed, **immediately** update the report file:

- `Status: open` → `resolved` | `skipped`
- Fill `Resolved via:` — what changed
- Fill `Resolution notes:` — brief explanation

This is **not batched** — each finding updates the report as it's resolved.

### Fix Agent

For subagent-dispatched fixes, the fix agent receives:
- Issue title, severity, finding type
- File path, problem description
- Chosen fix approach
- Project rules

The agent reads the target file, applies the fix, adds why-comments for non-trivial changes, updates tests if needed, and runs verification. Does not commit.

### Bounded Revalidation

After all fixes:
1. Confirm compliance risks are closed
2. Confirm quality fixes are complete
3. Revalidate only impacted sections — NOT full re-review

### Documentation Check

After all fixes and final verification, cp-fix checks if changes affect anything documented in `.ai/docs/`. If so, it informs the user and suggests running `/cp-docs`.

## Ad Hoc Save Gate

When there is no task folder in `.ai/tasks/`:
- Report is generated **in conversation only**
- Report is **not saved to disk** until user explicitly approves
- Violating this gate is a critical workflow error

## Change Impact

- Adding a new reviewer dimension: create template in `cp-review/`, update review dispatch logic
- Changing report format: impacts cp-fix parsing and cp-rules analysis
- Modifying severity levels: impacts assessment logic across cp-review and cp-fix
