---
name: implement
description: "Implement a docs/plans/ plan end to end, then hand off to land-feature. Use when a docs/plans/NNN-*.md plan exists with status authored and is ready to build."
disable-model-invocation: true
argument-hint: "target-project/module"
---

# Implement a plan

Executes a plan already authored by `plan-doc` in `docs/plans/`, then hands the
finished work to `land-feature` to close out.

> **Orient first:** read the target repo's `CLAUDE.md` and its `docs/plans/README.md`
> header — they govern this repo's doc set, invariants and plan-status vocabulary, not
> devkit's.

## When to use this

- A `docs/plans/NNN-*.md` plan exists with status `authored` in `docs/plans/README.md`.
- Skip if no plan exists yet — run `plan-doc` first.

## Steps

1. **Find the plan.** If the user names one, read `docs/plans/NNN-slug.md` directly;
   otherwise check `docs/plans/README.md` for the plan marked `authored` and confirm
   with the user which one to build.
2. **Work the plan's steps in order.** Each step lists Files / Do / Verify — implement
   Do, then run Verify before moving to the next step. A failing Verify blocks the
   next step; don't skip ahead or batch steps together.
3. **Close out via `land-feature`.** It runs the full suite and classifies any failure
   as inherited or a regression, appends the `docs/COMPLETE_ACTIONS.md` entry, flips the
   plan's `docs/plans/README.md` row to `implemented`, reconciles `CLAUDE.md`/`README.md`
   if an invariant or the public surface moved, and commits once you confirm. Don't
   duplicate any of that here.

## What not to do

- Don't invent scope beyond what the plan's Steps describe — new ideas go back into
  `plan-doc`, not into the implementation.
- Don't touch `CLAUDE.md` invariants yourself — that's `land-feature`'s job, so the
  changelog and the invariant edit land together.
- Don't skip a step's Verify command because it "obviously works."
- Don't assert against a function's return shape from memory — read it first. When the
  test is about *absence*, assert shape-independently (serialize the payload and search
  it) so it survives the shape changing.
- Don't use discovery plans under `docs/plans/discovery/`
