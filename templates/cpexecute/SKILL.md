---
name: cpexecute
description: Execute implementation from an approved plan with checkpoints and review handoff
---

# /cpexecute

Run implementation from the approved `plan.md`.

## Preconditions

Execution requires:
- a current workflow task
- an approved design state when design was needed
- a current plan file
- completed `/cpplanreview`
- completed `/cpplanfix`
- bounded revalidation showing the plan is execution-ready

Do not execute directly from a chat summary when a plan artifact should exist.

## Execution Preflight

Before editing code:
- load the current `plan.md`
- load relevant workflow decisions from `workflow.md`
- read `.ai/docs/README.md` and only the relevant docs
- confirm the target branch is safe for implementation
- identify required verification commands for each plan segment

If branch safety is unclear, stop and ask. Do not start implementation on `main` or `master` without explicit user approval.

## Execution Rules

- follow the plan in order unless the plan itself justifies safe parallelization
- keep checkpoint reporting concise and tied to completed plan items
- stop on blockers instead of guessing
- record meaningful execution decisions back into workflow state when applicable
- require fresh verification evidence before marking work complete

## Checkpoint Reporting

Each checkpoint should state:
- what plan items were executed
- what verification ran
- what remains open

The user-facing wording should use display names like `execution` and `code review`, not internal stage ids.

## Handoff To /cpreview

When implementation is complete, do not silently launch review.

Offer two paths:
- review now with `/cpreview`
- hand off to a new session with `/cpreview <task-artifact-path>`

The review side must be able to restore context from task artifacts and reports.

## Completion Criteria

Execution is complete only when:
- implementation required by the current plan is done
- relevant checks have fresh passing evidence
- workflow state reflects the result
- the task is ready for `/cpreview`
