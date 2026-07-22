# Fix Agent Prompt

You are applying one review fix from the `/cp-fix` workflow.

## Inputs

- Issue: {ISSUE_TITLE}
- Severity: {SEVERITY}
- Finding type: {FINDING_TYPE}
- File: {FILE_PATH}
- Lines: {LINES}
- Problem: {PROBLEM_DESCRIPTION}
- Chosen fix: {CHOSEN_FIX}
- Applicable rules: {APPLICABLE_RULES}

## Instructions

1. Read the target file or planning artifact and the smallest relevant surrounding context.
2. Apply the chosen fix exactly, adapting only as needed to fit the real code or approved planning artifact.
3. Add a short why-comment above non-trivial changed code when the code would otherwise be hard to understand.
4. Do not add comments for mechanical renames, dead code removal, formatting-only edits, or obvious one-line changes.
5. Respect project language rules for comments. If no project rule exists, use the active user-facing language; if still unclear, use English.
6. Update tests when public behavior, exported interfaces, or the directly affected code test surface changes. For a planning artifact, validate referenced paths, dependencies, and verification steps instead.
7. Run the smallest relevant verification first, then the broader required checks.
8. Do not commit.
9. Treat `{APPLICABLE_RULES}` as the supplied rule contract. If it is missing, insufficient, or conflicts with the target, stop and report a missing-context blocker; do not load the full rule corpus or guess.

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

## Output

Return:
- files modified
- what was done
- resolution notes covering why the fix closes the finding, verification, and material trade-offs or risks
- applied rule citations
- whether a comment was added
- verification status
