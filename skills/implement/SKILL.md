---
name: implement
description: Execute a specs/ plan end to end, one step at a time, then hand off to finalize. Trigger on:- implement, code this, follow the plan, build this, write tests.
disable-model-invocation: true
argument-hint: "plan path or target-project/module"
model: claude-sonnet-5
---

# Implement a plan

Executes a plan already authored by `plan-doc` at `specs/NNN-<slug>/plan.md`, then hands
the finished work to `finalize` to close out. Follows the plan exactly; flags ambiguity
instead of guessing.

## When to use this

- A `specs/NNN-<slug>/plan.md` exists with `status: authored`.
- Skip if no plan exists yet — run `plan-doc` first.

## Procedure

1. **Read `.specify/memory/constitution.md`**, then the plan in full. Identify every
   deliverable. If the user named a plan, read it directly; otherwise take the one with
   `status: authored` from `specs/README.md` and confirm which to build.

2. **Work the steps in order.** Each lists Files / Do / Verify — implement Do, then run
   Verify before the next step. A failing Verify blocks the next step; don't skip ahead
   or batch steps.

3. **Write tests alongside each unit**, matching the style already in the codebase (look
   at one existing test file first). Run them after each step.

4. **On an ambiguous or conflicting step, park it.** Write
   `specs/NNN-<slug>/gates/NNN-<what>.md` (`status: awaiting-input`) with the options,
   and stop — this is a long-running skill, so it parks rather than blocking. Resume on
   `status: answered` per the constitution's gate protocol.

5. **Close out via `/finalize`** — done-checks, changelog, version, plan-index flip to
   `implemented`, commit on confirm. Don't duplicate any of that here. (A setup with its
   own ledger contract runs its overlay — e.g. `/land-feature` — instead.)

## What not to do

- Don't invent scope beyond the plan's Steps — new ideas go back to `plan-doc`.
- Don't make architectural decisions mid-build — park them (step 4).
- Don't skip a step's Verify because it "obviously works".
- Don't assert a function's return shape from memory — read it first. When the test is
  about *absence*, assert shape-independently (serialize the payload and search it).
