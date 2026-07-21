## Resolution Communication

Before explaining a fix, determine the language required by project rules. Write the explanation,
verification result, blocker, and report-resolution fields in that language. If rules do not specify a
language, use the language of the user's current conversation; a bare fix command inherits the preceding
user messages. If conversation language is unavailable, use the active user-facing language. Keep
identifiers, API names, paths, and code unchanged.

For every non-trivial fix, make the outcome understandable without reading the diff first:
- what changed;
- why that change closes the finding;
- which behavior or failure scenarios were verified;
- real trade-offs and risks introduced by the chosen fix, such as API or UX changes, compatibility,
  performance, operational complexity, or stricter validation.

When several reasonable fixes exist before editing, present each as `A)` / `B)` with what changes,
advantages, disadvantages, and when to choose it. Do not invent alternatives or trade-offs for a simple,
unambiguous repair, such as adding a clearly missing test.
