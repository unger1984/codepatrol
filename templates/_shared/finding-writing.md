## Finding Communication

Before drafting findings, determine the language required by project rules. Write the finding's title,
problem, impact, and fix in that language. If rules do not specify a language, use the language of the
user's current conversation; a bare review command inherits the preceding user messages. If conversation
language is unavailable, use the active user-facing language. Keep identifiers, API names, paths, and code
unchanged.

Make every non-trivial finding understandable without reading the reviewed code first:
- describe the observed behavior or code condition;
- explain the triggering scenario and causal chain to the concrete impact;
- state why that impact matters to the user, system, or future maintainer;
- give an actionable fix, including a code snippet where it removes ambiguity.

When more than one reasonable fix exists for a non-trivial finding, list each as `A)` / `B)` and state:
- what changes;
- advantages and disadvantages;
- when to choose it.

Do not invent alternatives for a simple, unambiguous repair, such as adding a clearly missing test. State
the direct fix instead.
