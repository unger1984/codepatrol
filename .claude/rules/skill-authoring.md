---
description: Rules for writing and maintaining skill templates
globs: ["templates/**/*.md"]
alwaysApply: false
---

## Anti-lock and anti-hang rules

- Every skill MUST have explicit completion criteria — a finite list of conditions after which the skill stops
- Every loop or retry in a skill MUST have a maximum iteration count (no unbounded loops)
- If a skill dispatches a subagent, it MUST define a timeout or max-steps policy — never wait indefinitely
- If a skill requires user input and the user doesn't respond, the skill MUST NOT retry the same question — it should proceed with a default or stop
- Skills MUST NOT re-read the same files repeatedly in a loop hoping for different results
- "When in doubt, ask the user" — but only once per question. If blocked, stop and report the blocker.

## Anti-contradiction rules

- A skill MUST NOT contain instructions that contradict each other (e.g., "always do X" in one section and "never do X" in another)
- When a skill references another skill's output or artifacts, it MUST use the same terminology and format expectations
- If two skills can run in sequence (e.g., cp-plan → cp-execute), their interfaces MUST be compatible:
  - output format of skill A must match expected input of skill B
  - status/completion criteria must not conflict
- Shared concepts (e.g., "completion criteria", "blocker policy", "user approval") MUST have consistent definitions across all skills — define once in `_shared/`, include everywhere
- When adding a new constraint to a skill, grep all other skills for conflicting constraints on the same topic before committing

## Required skill structure

Every skill template MUST include:
- Completion criteria — when the skill is done (finite, verifiable conditions)
- Blocker policy — what to do when stuck (ask user, stop, or fallback)
- Anti-patterns section — what the skill must NOT do (prevents common failure modes)
