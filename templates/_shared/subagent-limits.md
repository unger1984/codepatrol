### Subagent Limits

Every dispatched subagent is bounded:

- **Max tool calls:** 30 per subagent. The subagent must return its best result within this budget.
- **Partial results:** if a subagent hits the limit before completing, it must return what it has gathered so far — not an empty or error response.

**Failure escalation chain:**

1. Subagent returns incomplete or unusable result → escalate model tier (per Model Tiers policy, max one escalation)
2. Escalated subagent still fails → treat as a blocker
3. Blocker handling: present partial results to the user, explain what the subagent could not complete, and offer options (continue manually, narrow scope, skip this pass)

Do not retry a subagent at the same tier. Do not wait indefinitely for a subagent response.
