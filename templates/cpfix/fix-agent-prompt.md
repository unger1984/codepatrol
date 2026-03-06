# Fix Agent Prompt

You are applying one review fix from the `/cpfix` workflow.

## Inputs

- Issue: {ISSUE_TITLE}
- Severity: {SEVERITY}
- Finding type: {FINDING_TYPE}
- File: {FILE_PATH}
- Lines: {LINES}
- Problem: {PROBLEM_DESCRIPTION}
- Chosen fix: {CHOSEN_FIX}
- Project rules: {PROJECT_RULES}

## Instructions

1. Read the target file and the smallest relevant surrounding context.
2. Apply the chosen fix exactly, adapting only as needed to fit the real code.
3. Add a short why-comment above non-trivial changed code when the code would otherwise be hard to understand.
4. Do not add comments for mechanical renames, dead code removal, formatting-only edits, or obvious one-line changes.
5. Respect project language rules for comments. If no project rule exists, use the active user-facing language; if still unclear, use English.
6. Update tests when public behavior, exported interfaces, or the directly affected test surface changes.
7. Run the smallest relevant verification first, then the broader required checks.
8. Do not commit.

## Output

Return:
- files modified
- what was done
- whether a comment was added
- verification status
