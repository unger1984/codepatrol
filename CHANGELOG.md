# 24.07.2026 v0.6.8

- Добавлен `handoff.md` рядом с планом: он сохраняет существенные, подтверждённые изменения пути реализации, чтобы ревью отличало их от самовольных отступлений.
- Вопросы о стратегии исправлений теперь принимают свободный текст и смешанные правила для отдельных находок; агент пересказывает, как понял выбор, и ждёт подтверждения перед правками.

# 24.07.2026 v0.6.7

- Reviews now collect the full result set: compliance remains first, but its findings no longer cancel architecture, security, testing, convention, or compatibility checks.
- Review completion now explicitly hands the report to the user: ad-hoc reviews offer save, context-only fixes, or finish; task reviews state the saved report path and ask before starting fixes.
- `/cp-fix` now requires a selected scope and processing style before any change; “fix it” and “do it” do not choose a strategy.
- When a platform lacks an interactive question tool, the agent asks the equivalent question in normal conversation and waits for an explicit answer.
- The generator validates these rules for Claude, Codex, Cursor, OMP, and OpenCode.
