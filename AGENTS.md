# Repository Guidelines

## Project Structure & Module Organization
CodePatrol is template-driven. Keep source-of-truth content in templates, then generate platform output.

- `templates/` — skill templates with `{{PLACEHOLDER}}` variables (edit here first)
- `platforms/` — platform values (`claude.env`, `codex.env`)
- `plugins/codepatrol/skills/` — generated plugin skill output (do not hand-edit)
- `.claude-plugin/` — Claude plugin manifest
- `install.sh` — build/install entrypoint

Example flow: edit `templates/code-review/*` -> run `./install.sh build` -> verify changes in `plugins/codepatrol/skills/`.

## Build, Test, and Development Commands
- `./install.sh build` — regenerate `plugins/codepatrol/skills/` from templates.
- `./install.sh claude` — generate and install skills to `~/.claude/skills/`.
- `./install.sh codex` — generate and install skills to `~/.codex/skills/`.

Run from repo root: `cd codepatrol && ./install.sh build`.

## Coding Style & Naming Conventions
- Use concise Markdown with clear section headers.
- Keep templates platform-agnostic: no hardcoded project/framework specifics.
- Put platform differences only in `platforms/*.env`.
- Skill file text should be English.
- Shell scripts should be POSIX-friendly where practical; keep executable scripts in `chmod +x` state.

Naming patterns:
- Templates and generated skill directories use kebab-case (for example, `code-review-fix`).
- Environment variable placeholders use `UPPER_SNAKE_CASE` (for example, `{{AGENT_NAME}}`).

## Testing Guidelines
There is no dedicated automated test suite yet. Validation is command-based:

1. Run `./install.sh build` with no errors.
2. Inspect generated `plugins/codepatrol/skills/` output for expected substitutions.
3. Run `./install.sh claude` or `./install.sh codex` to verify installation flow.

When changing templates, include a quick manual verification note in the PR.

## Commit & Pull Request Guidelines
This repository currently has little/no commit history; use Conventional Commits for consistency:
- `feat: add codex install placeholder`
- `fix: correct template variable mapping`
- `docs: update contributor guide`

PRs should include:
- Purpose and scope (what changed, where, why)
- Before/after examples for template or generated output changes
- Commands run for verification (`./install.sh build`, install target)
- Linked issue (if applicable)

## Security & Configuration Notes
Do not commit secrets to `platforms/*.env`. Keep values generic and review generated files before publishing.
