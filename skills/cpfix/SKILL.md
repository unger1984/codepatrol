---
name: cpfix
description: Fix open code review findings from cpreview with priority for compliance before quality
---

# /cpfix

Process open findings from `/cpreview`.

## Source

Accept either:
- a saved review report path
- the latest review report from the current workflow task
- the current conversation context if review just finished

If the source is ambiguous, ask before proceeding.

## Processing Order

Only process `open` findings.

Default priority:
1. `compliance`
2. `quality`

Do not move to quality findings while unresolved compliance findings remain, unless one combined change is clearly safer and still keeps the review trail understandable.

## Fix Policy

Support:
- manual per item
- auto simple ask-user for complex cases
- custom user policy

If policy is not already clear, ask.

## Execution Rules

- parallelize only independent fixes
- update report tracking fields after each fix
- allow alternative fixes when there are real trade-offs
- run bounded revalidation before closing each finding
- run final project checks before declaring the code path complete

## Report Mutation

For each processed finding, update:
- status
- resolved via
- resolution notes

The report remains resumable across future `/cpfix` runs.

## Completion Criteria

This stage is complete when selected findings are resolved with evidence, compliance findings are handled first, and final verification is fresh.
