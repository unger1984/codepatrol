# Handoff and Flexible Fix Policy Implementation Plan

**Goal:** Add an auditable handoff artifact and user-friendly free-text fix-policy selection.

## Tasks

1. Update `templates/using-codepatrol/SKILL.md` and generated task-folder documentation to define optional,
   append-only `handoff.md`, its entry fields, material-change escalation, and its relationship to design and plan.
2. Update `templates/cp-review/SKILL.md` so prepared context includes cited handoff entries when present and review
   evaluates authorized adaptations independently rather than reporting them automatically as plan violations.
3. Update `templates/cp-fix/SKILL.md` to ask one plain-language question at a time, accept free-text or mixed
   policies, restate the parsed policy, and wait for confirmation before any mutation or parallel dispatch.
4. Update `.ai/docs`, README task-folder diagrams, `install.sh`, and `install.ps1`; regenerate `skills/` and run
   `./install.sh validate` plus `git diff --check`.
