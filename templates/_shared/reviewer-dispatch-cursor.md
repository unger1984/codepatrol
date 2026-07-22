- When `requires_deep_compliance` is true, dispatch the powerful compliance reviewer first with only the
  reviewed files and minimal prepared context.
- After compliance is acceptable, define quality reviewers as `.md` agents with YAML frontmatter.
- Use `background: true` for independent quality passes and set each reviewer's configured model tier.
