---
description: Rules for writing and maintaining skill templates and build scripts
paths: ["templates/**/*.md", "install.sh", "install.ps1"]
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
- If two skills can run in sequence (e.g., cp-review → cp-fix), their interfaces MUST be compatible:
  - output format of skill A must match expected input of skill B
  - status/completion criteria must not conflict
- Shared concepts (e.g., "completion criteria", "blocker policy", "user approval") MUST have consistent definitions across all skills — define once in `_shared/`, include everywhere
- When adding a new constraint to a skill, grep all other skills for conflicting constraints on the same topic before committing

## Cross-platform compatibility (AI platforms)

When editing templates or shared partials, verify impact on ALL supported AI platforms (Claude, Codex, Cursor):

- If adding a new `{{PLACEHOLDER}}` variable, ensure it is defined in every `platforms/*.env` file
- If adding `{{@platform-include:name}}`, create a corresponding partial (`_shared/{name}-{platform}.md`) for every platform
- If a template behavior depends on platform capabilities (e.g., parallel agents, progress tracking), use platform variables to abstract the difference — never hardcode platform-specific instructions in templates
- When in doubt, check all env files: `ls platforms/*.env` and verify each has the variable

## Cross-platform compatibility (OS)

Build and install scripts exist in two variants: `install.sh` (Unix/macOS) and `install.ps1` (Windows/PowerShell). They MUST stay in sync:

- When changing logic in `install.sh`, apply the same change to `install.ps1` and vice versa
- When adding a new command (e.g., a new platform), add it to both scripts
- When adding or removing legacy skill names, update the list in both scripts
- Shell commands in skill templates must provide both Unix and PowerShell variants: `date +%H%M` / `Get-Date -Format 'HHmm'`, `mkdir -p` / `New-Item -ItemType Directory -Force`

## Documentation sync rule

When any skill template (`templates/`), shared partial (`templates/_shared/`), or skill behavior changes:
- Check and update `README.md` and `README.ru.md` if the change affects user-facing behavior, data storage, commands, or workflow
- Check and update `.ai/docs/` if it exists and covers the changed area
- This includes: new features, new artifact types, new accepted inputs, changed workflow stages, new directories in `.ai/`

Do not skip documentation updates — they are part of the change, not a follow-up task.

## Change checklist

Before committing any change to `templates/` or `templates/_shared/`:

1. Edit templates, NEVER edit `skills/` directly
2. Run `./install.sh build` to regenerate `skills/`
3. Grep other templates for conflicting instructions on the same topic
4. If the change affects data format between skills (e.g., review report → fix input), verify the full chain still works
5. If ad hoc behavior is affected — verify the save gate: no file writes without user confirmation outside workflow mode
6. Never hardcode dynamic values (timestamps, versions) — always get them via shell commands (`date`, reading from files)
7. Update version in `plugin.json` and `marketplace.json` if releasing
8. Update `README.md`, `README.ru.md`, and `.ai/docs/` per the documentation sync rule below

See [Known Issues](/.ai/docs/shared/known-issues.md) for detailed context on each point.

## Required skill structure

Every skill template MUST include:
- Completion criteria — when the skill is done (finite, verifiable conditions)
- Blocker policy — what to do when stuck (ask user, stop, or fallback)
- Anti-patterns section — what the skill must NOT do (prevents common failure modes)
