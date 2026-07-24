# Review and Fix Interaction Gates

## Goal

Prevent `/cp-review` and `/cp-fix` from silently skipping a user decision when an interactive question tool is
unavailable in Codex. Ensure a review finishes with a clear report handoff and a fix workflow starts only after
the user explicitly selects a fix policy.

## Scope

- `cp-review` report completion and handoff.
- `cp-fix` policy selection before the first mutation.
- Text-based question fallback for every supported platform.
- Generated-skill validation for the new mandatory rules.

## Review Completion Gate

`cp-review` completes all required compliance and quality passes, aggregates one report, and then stops for a
report handoff.

- **Task-scoped review:** save `review.md` in the current task folder, tell the user the exact path, then ask
  whether to start `/cp-fix` or finish.
- **Ad hoc review:** present the report inline, then ask the user to save it, start `/cp-fix` without a file, or
  finish. Do not save until the user chooses saving.
- An offer to use `/cp-fix` does not start it. The next workflow begins only after the user explicitly chooses it.

The report handoff happens only after all mandatory review dimensions have a verdict. An open compliance finding
marks the final assessment as `NEEDS_CHANGES`, but does not prevent the independent quality passes from completing.

## Fix Intake Gate

`/cp-fix`, a request such as “fix it”, or “do it” authorizes intake only. It never selects a policy.

Before any code edit, subagent dispatch, fix command, or report-status mutation, `cp-fix` must show the number of
open findings and request two explicit choices:

1. severity scope: critical only, critical plus important, or all findings;
2. processing style: manual per finding, automatic safe fixes with approval for consequential or ambiguous work,
   or a custom user policy.

If independent findings could be handled concurrently, the agent presents the proposed groups and requests a
separate explicit approval. Sequential processing remains the default.

The agent may say the policy is already selected only when the current conversation contains an explicit option
choice or an applicable project rule states one. A vague instruction to start fixing is not an option choice.

## Question Fallback

When the platform exposes an interactive question tool, use it. When it does not, ask the same question in a normal
user-facing message with numbered choices and wait for an explicit reply. Tool unavailability never authorizes an
assumption or workflow continuation.

## Platform Design

Keep workflow semantics in shared templates. Platform-specific dispatch partials retain only their native syntax;
they must not redefine the gates. The text fallback is platform-neutral, so it belongs in shared skill templates.

## Verification

- Regenerate the Claude output from templates.
- Run all-platform generated-skill validation.
- Extend validation to assert the new review handoff, fix intake, and question-fallback markers in every generated
  platform output.
- Inspect generated Codex `cp-review` and `cp-fix` files to confirm the fallback language is present.

## Non-goals

- Adding or changing a Codex UI control for questions; tool availability belongs to Codex.
- Automatically launching `/cp-fix` after review.
- Replacing meaningful per-finding alternatives with a generic approval prompt.
