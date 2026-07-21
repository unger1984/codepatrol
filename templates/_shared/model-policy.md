Choose the cheapest model that can handle the task. If the platform supports model selection for subagents, use it.

### Model Tiers

| Tier | Description | Use when |
|------|-------------|----------|
| **fast** | Cheapest/fastest available | Simple, well-scoped tasks with clear instructions |
| **default** | Mid-range | Most subagent work requiring comprehension and judgment |
| **powerful** | Most capable available | Complex reasoning, ambiguous constraints, tasks that failed at a lower tier |

### Platform Model Selection

Tiers are logical task categories, not platform model-role names. In particular, `default` does not
refer to a platform's `default` role or imply a fixed capability level. When a platform dispatches a
named agent definition, that definition selects the model or role.

### Ceiling Rule

Respect a capability ceiling only when the platform enforces one. Do not infer a ceiling from model-role
names or override the model selected by a platform agent definition.

### User Override

If project rules (CLAUDE.md, AGENTS.md) define a model mapping for tiers (e.g., `fast: haiku`,
`default: sonnet`), use it. User-defined mapping takes priority over automatic selection.

### Escalation on Failure

For failure handling and escalation, see Subagent Limits (included separately in each skill).