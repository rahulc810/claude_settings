---
name: resolve-review
description: Work through a code-review report's findings and fix them, in priority order, with confirmation on anything non-trivial. Use when asked to address, fix, or resolve review findings, act on a docs/reviews/ report, or clear Blocking items before landing a feature.
argument-hint: "report (path to docs/reviews/... file), which: all | blocking | should-fix | nit"
allowed-tools: Read, Edit, Grep, Glob, Bash
disable-model-invocation: true
---

# Resolve Review

Takes a `code-review` report and works through its findings, fixing them one at a time
in priority order. This skill remediates — it does not re-judge whether something is a
real issue. If a finding looks wrong on inspection, say so and skip it rather than
silently ignoring it or arguing it away.

## Assumptions (flag if wrong)

- The report is an `open`-status `code-review` output at
  `docs/reviews/<project>-<date>[-<plan-name>].md`, with findings grouped under
  **Blocking** / **Should-fix** / **Nit** headers, each with file:line, what's wrong, why
  it matters, and a suggested fix.
- Fixing scope is limited to what's named in the finding — not an invitation to refactor
  around it.

## Arguments

- `report` — path to the review report to work from. If omitted, look for the most
  recent file in `docs/reviews/` with `open` status and confirm it's the right one before proceeding.
- `which` — which severity tier(s) to address:
  - `all` (default) — Blocking, then Should-fix, then Nit, in that order.
  - `blocking` / `should-fix` / `nit` — just that tier.

## Workflow

1. **Read the report.** Parse out findings per severity tier, each with its file:line and
   suggested fix.

2. **Work Blocking items first, one at a time:**
   - State what you're about to change and why, briefly — a sentence, not a re-explanation
     of the finding.
   - Apply the fix.
   - If the fix isn't as simple as the report suggested (e.g. it touches more than the
     named lines, or the suggested approach doesn't actually work), stop and explain
     before proceeding rather than expanding scope silently.
   - If a finding looks wrong on closer inspection — not actually a bug, or the "fix"
     would break something else — say so and skip it. Note the disagreement in the
     summary at the end; don't just quietly leave it unfixed.

3. **Then Should-fix, same pattern.** These are lower-stakes — batch the straightforward
   ones and note them as you go rather than narrating each one individually, but still
   flag anything that turns out non-trivial.

4. **Then Nit**, only if `which` includes it. Offer to apply all of them at once (they're
   non-blocking by definition) or list them for the user to pick from — ask once, up
   front, rather than per-item.

5. **Summarize what happened**: fixed / skipped-with-reason / deferred, per item. Don't
   just say "done."

6. **Set the report's `Status:` to `worked-on`.** Never `closed` — only `code-review`
   closes a thread, after re-checking the fixes.

7. **Offer to re-run `code-review`** on the same scope to confirm the findings are
   actually resolved, rather than trusting this pass's own fixes. Don't run it
   automatically — ask first, since it may not be needed for a `nit`-only pass.

## Boundaries

- Don't fix things the report didn't flag, even if you notice them along the way — note
  them instead (a one-liner in the summary, or point at `/notice` if it looks like a
  recurring pattern).
- Don't reduce a Blocking or Should-fix finding's severity to make it easier to skip.
- If more than a couple of findings turn out to need real design decisions rather than
  straightforward fixes, stop and flag that the report may need `/planit` rather than
  direct patching — don't improvise architecture mid-fix.