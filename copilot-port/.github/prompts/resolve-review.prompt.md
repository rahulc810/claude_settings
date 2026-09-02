---
mode: agent
description: "Work through a code-review report's findings and fix them in priority order, with confirmation on anything non-trivial."
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
# Resolve Review

Input: `${input:args:report path (specs/NNN-<slug>/review.md) and which: all | blocking | should-fix | nit}`.

Takes a `/code-review` report and works through its findings, fixing them one at a time in
priority order. This remediates — it does not re-judge whether something is a real issue. If a
finding looks wrong on inspection, say so and skip it rather than silently ignoring it or
arguing it away.

## Assumptions (flag if wrong)
- The report is an `open`-status `/code-review` output with findings grouped under **Blocking**
  / **Should-fix** / **Nit**, each with file:line, what's wrong, why it matters, a suggested
  fix.
- Fixing scope is limited to what's named in the finding — not an invitation to refactor
  around it.

## Arguments
- `report` — path to the review report. If omitted, look for the most recent
  `specs/*/review.md` with `status: open` and confirm it's the right one.
- `which` — `all` (default: Blocking, then Should-fix, then Nit) / `blocking` / `should-fix` /
  `nit`.

## Workflow
1. **Read the report.** Parse findings per severity tier, each with file:line and suggested
   fix.
2. **Work the findings** in tier order. Two review-specific points:
   - A finding that looks wrong on inspection — not a real bug, or the fix would break
     something else — is a *skip with reason*, not a silent pass.
   - For Nit, ask once up front — apply all, or list for the user to pick — rather than
     prompting per item.
3. **Set the report's `status:` to `worked-on`** and bump `updated:`. Never `closed` — only
   `/code-review` closes a thread, after re-checking the fixes.
4. **Offer to re-run `/code-review`** on the same scope to confirm the findings are actually
   resolved. Don't run it automatically — ask first.

## Boundaries
- Don't fix things the report didn't flag, even if you notice them — note them instead.
- Don't reduce a Blocking or Should-fix finding's severity to make it easier to skip.
- If more than a couple of findings need real design decisions rather than straightforward
  fixes, stop and flag that the report may need `/designit` rather than direct patching.
