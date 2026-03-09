# Cursor Platform Support — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Cursor IDE as a third supported platform in CodePatrol with full build and install pipeline.

**Architecture:** New platform env file + two platform-specific partials + install.sh case + cross-platform rule. Follows existing pattern established by Claude and Codex platforms.

**Tech Stack:** Shell (POSIX), Markdown

---

### Task 1: Create `platforms/cursor.env`

**Files:**
- Create: `platforms/cursor.env`
- Reference: `platforms/claude.env`, `platforms/codex.env`

**Step 1: Create the env file**

```
ASK_USER=Ask the user a question using the built-in Ask Questions tool. You can continue other work while waiting for a response.
SKILLS_DIR=~/.cursor/skills
RULES_SOURCE=`.cursor/rules/*.mdc` files with frontmatter (description, globs, alwaysApply) and `AGENTS.md`
DISPATCH_AGENT=Define subagents as .md files in .cursor/agents/ with YAML frontmatter (name, description, model, background). Use background: true for parallel execution. Subagents can spawn sub-subagents.
PROGRESS_TOOL=Checkpoints (automatic snapshots before significant changes). No dedicated todo/checklist tool — track progress via clear status messages.
FILE_DISCOVERY=Use Semantic Search for meaning-based lookups and Search Files for name/pattern matching. Do not fall back to shell commands unless no dedicated tool is available.
WEB_RESEARCH=Use Web tool for search queries. Use Browser tool for interactive page inspection and screenshots. Prefer official documentation over blog posts.
DISPATCH_RESEARCHER=Define a research subagent in .cursor/agents/ with background: true, dispatch by name or let Agent auto-delegate based on description.
```

**Step 2: Verify all variables from claude.env are present**

Run: `grep -o '^[A-Z_]*=' platforms/claude.env | sort` and compare with `grep -o '^[A-Z_]*=' platforms/cursor.env | sort`

Expected: Same set of variable names.

---

### Task 2: Create `templates/_shared/aliases-cursor.md`

**Files:**
- Create: `templates/_shared/aliases-cursor.md`
- Reference: `templates/_shared/aliases-claude.md`

**Step 1: Create aliases file**

Same as Claude — no built-in `/review` conflict in Cursor:

```markdown
## Short Aliases

| User types | Resolve to |
|------------|-----------|
| `/review` | `/cp-review` |
| `/fix` | `/cp-fix` |
| `/docs` | `/cp-docs` |
```

---

### Task 3: Create `templates/_shared/rules-authoring-cursor.md`

**Files:**
- Create: `templates/_shared/rules-authoring-cursor.md`
- Reference: `templates/_shared/rules-authoring-claude.md`, `templates/_shared/rules-authoring-codex.md`

**Step 1: Create rules authoring guide for Cursor**

Content should cover:
- MDC format (`.mdc` files in `.cursor/rules/`) with YAML frontmatter
- Fields: `description`, `globs`, `alwaysApply`
- 4 application modes: Always Apply (`alwaysApply: true`), Apply Intelligently (requires `description`), Apply to Specific Files (`globs`), Apply Manually (`@rule-name`)
- File placement strategy (analogous to Claude's but with `.cursor/rules/` path)
- `AGENTS.md` support as alternative
- Anti-patterns
- Example

---

### Task 4: Update `install.sh`

**Files:**
- Modify: `install.sh`

**Step 1: Add `cursor` to usage()**

Add line: `  cursor   Generate and install skills to ~/.cursor/skills/`

**Step 2: Add `cursor` case**

After the `codex)` case, add `cursor)` case:
- Generate with `cursor.env` into a temp dir
- Clean installed skills in `~/.cursor/skills/`
- Copy generated skills to `~/.cursor/skills/`
- Clean up temp dir

Pattern: follow `codex)` case structure (temp dir approach).

**Step 3: Verify script syntax**

Run: `bash -n install.sh`

Expected: No errors.

---

### Task 5: Build and verify

**Step 1: Run build**

Run: `./install.sh build`

Expected: Success, no errors about missing includes.

Note: `build` uses claude.env — this just verifies existing templates still work after adding new shared partials.

**Step 2: Dry-run cursor generation**

Run a manual test — temporarily generate cursor output:

```bash
# Generate cursor skills to a temp dir
tmp=$(mktemp -d) && ./install.sh cursor 2>&1; echo "Exit: $?"
```

Verify: Skills generated and installed to `~/.cursor/skills/`, no errors about missing platform includes or variables.

**Step 3: Spot-check generated content**

Read a generated skill (e.g., `~/.cursor/skills/using-codepatrol/SKILL.md`) and verify:
- `{{PLACEHOLDER}}` values are substituted with cursor-specific values
- `{{@platform-include:aliases}}` resolved to cursor aliases
- `{{@platform-include:rules-authoring}}` resolved to cursor rules format
- No unresolved `{{...}}` placeholders remain

---

### Task 6: Add cross-platform rule to `skill-authoring.md`

**Files:**
- Modify: `.claude/rules/skill-authoring.md`

**Step 1: Add cross-platform compatibility rule**

Add a new section "Cross-platform compatibility" (in English) after "Anti-contradiction rules":

```markdown
## Cross-platform compatibility

When editing templates or shared partials, verify impact on ALL supported platforms (Claude, Codex, Cursor):

- If adding a new `{{PLACEHOLDER}}` variable, ensure it is defined in every `platforms/*.env` file
- If adding `{{@platform-include:name}}`, create a corresponding partial (`_shared/{name}-{platform}.md`) for every platform
- If a template behavior depends on platform capabilities (e.g., parallel agents, progress tracking), use platform variables to abstract the difference — never hardcode platform-specific instructions in templates
- When in doubt, check all env files: `ls platforms/*.env` and verify each has the variable
```

---

### Task 7: Update documentation

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `README.ru.md`
- Modify: `.ai/docs/shared/architecture.md`

**Step 1: Update `CLAUDE.md`**

Add `cursor` to Build section:

```bash
./install.sh cursor  # generate and install to ~/.cursor/skills/
```

Update first line to mention Cursor:

```
Project-aware AI skills for Claude Code, Codex CLI, and Cursor. ...
```

**Step 2: Update `.ai/docs/shared/architecture.md`**

- Add `cursor.env` to project structure diagram
- Add Cursor column to variables table
- Add `cursor` row to install.sh commands table
- Add `aliases-cursor.md` and `rules-authoring-cursor.md` to shared partials list

**Step 3: Update `README.md` and `README.ru.md`**

Add Cursor mentions alongside Claude Code and Codex CLI. Add `./install.sh cursor` to usage.

Read both files first to understand current structure before editing.

---

### Task 8: Commit

**Step 1: Stage and commit**

```bash
git add platforms/cursor.env \
  templates/_shared/aliases-cursor.md \
  templates/_shared/rules-authoring-cursor.md \
  install.sh \
  .claude/rules/skill-authoring.md \
  CLAUDE.md README.md README.ru.md \
  .ai/docs/shared/architecture.md \
  skills/
git commit -m "feat: добавить поддержку Cursor как третьей платформы"
```
