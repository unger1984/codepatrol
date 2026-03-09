# cp-fix

## Purpose

Process open findings from `/cp-review` — fix code, update tests, mutate report incrementally.

## When to read

- Fixing code after review
- Understanding fix policy and processing order
- Working with incremental report mutation
- Understanding fix agent subagent contract

## Related docs

- [cp-review](cp-review.md) — source of findings
- [cp-docs](cp-docs.md) — may be needed after fixes
- [Review System](../review-system.md) — report format and tracking details

---

## Role

**Implementation fixer.** Processes findings in report order, applies fixes, updates report.

## Report Source

Report loaded from (in priority order):
1. Explicit path (user argument)
2. Scan `.ai/tasks/` and `.ai/reports/` for reports with open findings
3. Current conversation context (if review just finished)

## Processing Order

Strictly in report order — do not reorder by type, severity, or own judgment.

## Fix Policy

Determined before starting:

| Parameter | Options |
|-----------|---------|
| Severity scope | critical only / critical + important / all |
| Processing style | manual per item / auto simple (ask for complex) / custom |

## Incremental Report Mutation (mandatory)

After each finding (not batched):
1. Apply fix or decide to skip
2. Run bounded revalidation
3. **Immediately update report file** (if exists)
4. Mark progress item as completed

## Documentation Check

After all fixes, check if changes affect `.ai/docs/`. If so, inform user and suggest `/cp-docs`. Do not invoke automatically.

## Parallelization

- Default: sequential processing
- Parallel: only with explicit user approval

## Subagents

| Role | Tier | Purpose |
|------|------|---------|
| Fix agent | By complexity | Fix a single finding |

## Change Impact

- Changing fix agent contract affects fix quality
- Changing report mutation format requires sync with cp-review
