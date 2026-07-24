# Review and Fix Interaction Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make review completion and fix-start decisions explicit, including a text fallback when a platform does not expose an interactive question tool.

**Architecture:** Keep common workflow rules in `cp-review` and `cp-fix` templates. Keep platform adapters limited to their native dispatch syntax. Validate required generated-language markers in both POSIX and PowerShell installers, then regenerate the Claude output.

**Tech Stack:** Markdown templates, Bash, PowerShell, generated multi-platform skill files.

## Global Constraints

- Edit `templates/` first; never hand-edit `skills/`.
- All skill text remains English and platform-agnostic.
- A missing interactive-question tool requires a numbered text question and an explicit reply; it never permits an assumed decision.
- Compliance findings affect the report verdict but do not suppress independent quality findings.
- `/cp-fix` must not edit code, dispatch a fixer, invoke a fix command, or mutate report status before an explicit fix policy exists.

---

### Task 1: Define review completion and report handoff

**Files:**
- Modify: `templates/cp-review/SKILL.md`
- Modify: `templates/_shared/reviewer-dispatch-{claude,codex,cursor,omp,opencode}.md` only if an adapter repeats the obsolete clean-compliance gate

**Produces:** a single review flow in which every required quality dimension has a verdict before report handoff, with distinct task-scoped and ad-hoc handoff rules.

- [ ] **Step 1: Replace the compliance stop condition with report-verdict semantics**

  In `Review Order`, retain compliance as the first pass. Remove language that stops or prevents quality work merely because compliance found an open violation. State instead that open compliance findings produce `NEEDS_CHANGES`, while independent quality dimensions still complete before aggregation.

- [ ] **Step 2: Make quality coverage unconditional before handoff**

  Change `Quality Pass` and `Execution Model` wording so scope controls direct versus delegated execution and grouping, not whether quality is skipped. Preserve the five explicit verdicts: architecture, security/reliability, testing/verification, conventions, and compatibility.

- [ ] **Step 3: Add a mandatory report handoff gate**

  Add a section immediately after report generation:

  - task-scoped: save `.ai/tasks/<task>/review.md`, state its exact path, then ask whether to start `/cp-fix` or finish;
  - ad hoc: present the complete report, then ask whether to save it, start `/cp-fix` without a file, or finish;
  - an offer or mention of `/cp-fix` does not start the workflow; wait for an explicit choice.

- [ ] **Step 4: Add a platform-neutral question fallback**

  Add one shared rule near each handoff question: use `{{ASK_USER}}` when available; otherwise ask the same numbered question in a normal user-facing message and wait for an explicit reply. State that unavailable tooling cannot authorize an assumption.

- [ ] **Step 5: Inspect generated review output**

  Run: `./install.sh build`

  Inspect: `skills/cp-review/SKILL.md`

  Expected: no statement says an open compliance finding suppresses quality passes; both report-storage branches and the text-question fallback are present.

### Task 2: Require a policy choice before fixing

**Files:**
- Modify: `templates/cp-fix/SKILL.md`
- Modify: `templates/_shared/fixer-dispatch-{claude,codex,cursor,omp,opencode}.md` only if an adapter can independently start a fixer before the common gate

**Produces:** a deterministic fix-intake phase that blocks every mutation until the user selects scope and processing style.

- [ ] **Step 1: Define the Fix Intake Gate before progress or dispatch**

  Add a top-level gate after report-source selection. It must require the agent to report open-finding counts and ask for both choices before any edit, command that changes code, fixer dispatch, or report status update:

  1. severity scope: critical only / critical plus important / all;
  2. processing style: manual per finding / automatic safe fixes with approval for consequential or ambiguous work / custom policy.

- [ ] **Step 2: Define what counts as a selected policy**

  State that `/cp-fix`, “fix it”, “do it”, or an equivalent instruction authorizes intake only. A policy is preselected only by an explicit option choice in the current conversation or an applicable project rule. Prohibit claiming that a vague instruction already chose an implementation path.

- [ ] **Step 3: Preserve per-finding and parallel approval gates**

  Keep the existing Manual Per Item Gate and safe-fix restrictions. Require a separate approval after displaying independent parallel groups; no answer means sequential work in report order. Add the numbered text-question fallback beside both the policy and parallelization questions.

- [ ] **Step 4: Add the anti-bypass rule**

  Add an anti-pattern explicitly prohibiting edits, dispatch, or status mutation before the Fix Intake Gate is satisfied. Ensure it names the common failure: treating a generic request to start as a selected policy.

- [ ] **Step 5: Inspect generated fixer output**

  Run: `./install.sh build`

  Inspect: `skills/cp-fix/SKILL.md`

  Expected: the intake choices, the definition of explicit selection, the text fallback, and the pre-mutation prohibition are visible in the generated file.

### Task 3: Synchronize documentation with the interaction contract

**Files:**
- Modify: `.ai/docs/domains/skills/cp-review.md`
- Modify: `.ai/docs/domains/skills/cp-fix.md`
- Modify: `.ai/docs/domains/review-system.md`
- Modify: `.ai/docs/domains/skills-reference.md` only if its summary describes the obsolete clean-compliance stop condition

**Produces:** AI-facing documentation that describes the actual report and fix decisions without promising a Codex UI tool.

- [ ] **Step 1: Update the two-pass review description**

  In `cp-review.md` and `review-system.md`, state that compliance runs first and can set `NEEDS_CHANGES`, but independent quality checks still run before the unified report. Update the Mermaid flow to route the completed report through a user handoff decision rather than directly to `/cp-fix`.

- [ ] **Step 2: Document report handoff branches**

  In `cp-review.md`, retain automatic task-scoped saving but add the required post-save choice. Document the three ad-hoc options and the requirement to wait for an explicit response.

- [ ] **Step 3: Document fix intake and fallback behavior**

  In `cp-fix.md`, document both policy choices, separate parallel approval, and the rule that “fix it” starts intake only. In both detailed skill docs, state that plain numbered text is the fallback when the platform lacks an interactive question tool.

- [ ] **Step 4: Review documentation terminology**

  Run: `rg -n -S 'after clean compliance|stops before quality|open compliance violation|Run /cp-fix now' .ai/docs templates`

  Expected: remaining matches are either deliberately rewritten to the new behavior or removed; no documentation promises that open compliance stops quality or that `/cp-fix` starts automatically.

### Task 4: Validate the generated contract on every platform

**Files:**
- Modify: `install.sh:200-280`
- Modify: `install.ps1:220-260`
- Regenerate: `skills/`

**Produces:** cross-platform generation checks that fail if a future edit removes the interaction gates.

- [ ] **Step 1: Replace obsolete validation markers**

  In both validation functions, remove the assertion for `stop before quality with \`NEEDS_CHANGES\``. Replace it with a marker that proves quality coverage completes before report handoff and a marker that proves an open compliance finding changes the verdict rather than cancelling quality work.

- [ ] **Step 2: Add review-handoff marker assertions**

  In both installers, assert generated `cp-review/SKILL.md` contains stable phrases for:

  - explicit report handoff;
  - the ad-hoc save/start/finish choice;
  - the numbered text-question fallback.

- [ ] **Step 3: Add fix-intake marker assertions**

  Assert generated `cp-fix/SKILL.md` contains stable phrases for:

  - Fix Intake Gate;
  - both required policy choices;
  - generic start commands authorizing intake only;
  - no mutation before explicit policy selection;
  - numbered text-question fallback.

- [ ] **Step 4: Regenerate and validate**

  Run:

  ```bash
  ./install.sh validate
  ./install.sh build
  git diff --check
  git diff --quiet skills/
  ```

  Expected: all five platforms validate, Claude output is regenerated and current, whitespace check passes, and no ungenerated `skills/` diff remains after the build.

- [ ] **Step 5: Validate the PowerShell mirror when available**

  Run on PowerShell-capable environment:

  ```powershell
  .\install.ps1 validate
  ```

  Expected: the same marker contract passes for all generated platforms. If PowerShell is unavailable on the execution host, record this as an environment-limited check rather than weakening the script.

## Final Acceptance Checks

- A branch-wide ad-hoc review cannot move to fixing or saving before it presents the completed report and asks for a choice.
- A task-scoped review saves its report, tells the user where it is, and asks before starting fixes.
- A generic “fix it” command cannot result in a code mutation until scope and processing style are explicitly chosen.
- When no interactive question tool is exposed, the skills require numbered plain-text choices and an explicit reply.
- `./install.sh validate` and `./install.sh build && git diff --quiet skills/` pass.
