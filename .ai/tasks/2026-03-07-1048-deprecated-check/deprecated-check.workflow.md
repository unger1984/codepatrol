# Workflow: deprecated-check

## Task

Add deprecated API usage detection to the code review skill. The reviewer should catch usage of deprecated APIs from libraries and frameworks. Project rules may allow ignoring specific deprecated items or all of them.

## Status

done

## Artifacts

- Design: deprecated-check.design.md
- Plan: deprecated-check.plan.md

## Stage Tracking

- [x] Clarification — done
- [x] Research — done
- [x] Approach options — done
- [x] Solution outline — done
- [x] Research refresh — done
- [x] Design — done
- [x] Plan — done
- [x] Plan review — done (APPROVED)
- [x] Plan-review fixes — skipped (no findings)
- [x] Plan revalidation — skipped (no findings)
- [x] Execution — done
- [x] Code review — done (APPROVED)
- [x] Code-review fixes — skipped (no findings)
- [x] AI docs update — done (updated in execution stage 3)

## Decisions

- Scope: standard (same as other review dimensions)
- New dimension: Compatibility (deprecated API + version compatibility + breaking changes)
- Default severity: Minor
- Tier: fast
- Rules override: instruction in prompt — skip if project rules allow specific deprecated or disable check
- Task complexity: small

## Notes

- Target: review skill template (`templates/cp-review/`)
- Feature: detect deprecated API calls in reviewed code
- Rules integration: project rules can whitelist specific deprecated items or disable the check entirely

## Log

- `10:48` **/cp-idea** — workflow started, new task created
- `10:49` **/cp-idea** — clarification: scope standard, severity Minor, new dimension Compatibility, rules override via prompt
- `10:52` **/cp-idea** — research subagent → review structure confirmed, 3 severity levels, 4 dimensions, no conflicts
- `10:55` **/cp-idea** — approach confirmed: new Compatibility dimension with dedicated reviewer prompt
- `10:56` **/cp-idea** — outline confirmed (3 sections)
- `10:58` **/cp-idea** — research refresh → no conflicts, reviewer format confirmed
- `13:52` **/cp-idea** — design written and approved, handoff to /cp-plan
- `13:54` **/cp-plan** — plan written (4 stages), rules pre-check passed, handoff to /cp-plan-review
- `13:55` **/cp-plan-review** — APPROVED, 0 findings, plan execution-ready
- `14:06` **/cp-execute** — all 4 stages done, build passes, all 4 insertion points verified
- `14:07` **/cp-review** — APPROVED, 0 findings, workflow complete
