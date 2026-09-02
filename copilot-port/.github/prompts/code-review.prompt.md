---
mode: agent
description: "Review a diff or a plan's implementation for correctness, quality and plan adherence, bucketing findings by severity."
tools: ['codebase', 'search', 'editFiles', 'changes', 'runCommands']
---
# Code Review

Input: `${input:scope:full | plan <name> | running-review [report]}`.

Reviews on two axes together: **does it do what the plan said**, and **is it good code** (bugs,
security, tests, style). Findings are bucketed by severity, not dumped as a flat list. This
reports and re-verifies only — it never fixes anything.

## When to use this
- Before landing or merging, or to check an implementation against its plan doc.
- Not for architecture questions with no diff in hand — that's `/improve`.
- To *fix* what this finds, run `/resolve-review`.

## Assumptions (flag if wrong)
- Plans live at `specs/NNN-<slug>/plan.md`. If that path doesn't exist, search the project,
  then proceed as a pure quality review and say so.

## Scope
- `full` — the whole codebase, cross-checked against every `specs/*/plan.md`.
- `plan <name...>` — only the code the named plan(s) describe.
- `running-review [report]` — re-check fixes against an existing report. If `report` omitted,
  take the most recent with `Status: worked-on`; if none, say so and stop.

## Steps
1. **Resolve the project.** Confirm it's a git repo. If not, review files directly and say
   diff-based scoping is unavailable.
2. **Load context for the scope.**
   - `full` — read every `specs/*/plan.md`, then survey the codebase.
   - `plan <name...>` — read the plan doc(s) in full *first*: decisions, architecture,
     locked-in details. Then find the code, preferring `git diff` against the base branch.
   - `running-review` — read the existing report in full including any `## Resolution`
     section. Re-check each item marked Fixed against current code rather than trusting the
     note; re-examine anything Skipped or Deferred.
3. **Review both axes together.**
   - **Plan adherence** (only with a plan doc in hand) — flag both *deviations* and *plan
     gaps*. Let severity reflect your confidence.
   - **Quality** — correctness, security (injection, secrets, auth gaps, unsafe
     deserialization), test coverage for the changed logic, consistency with the codebase's
     conventions (not your own preferences).
4. **Bucket every finding.** **Blocking** (bugs, security, plan deviations that must be fixed
   before landing) / **Should-fix** (real but not launch-blocking) / **Nit** (style, naming,
   preference). Don't inflate severity to look thorough; don't bury real issues under nits.
5. **Write or update the report** at `specs/NNN-<slug>/review.md`:
   - `status:` + `updated:` header, scope at top, then counts by severity.
   - Findings grouped by severity, each with file:line, what's wrong, why it matters, a
     suggested fix.
   - `running-review` appends a `## Re-review — <date>` section — it doesn't rewrite history.
   - Set `status: closed` if no Blocking or Should-fix remain, else `open`.
   - Give a concise inline summary in chat too: the counts, then the Blocking items in full.
     Don't just say "see the report".

## What not to do
- Don't fix anything.
- No plan doc found for scope `plan <name>`: say so and stop; don't guess what the plan said.
- Nothing changed since the plan started: say so plainly rather than manufacturing findings.
