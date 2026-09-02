---
mode: agent
description: 'Execute a specs/ plan end to end, one step at a time, then hand off to finalize.'
tools: ['codebase', 'search', 'editFiles', 'runCommands', 'runTests']
---
# Implement a plan

Input: `${input:plan:plan path or target-project/module}`.

Executes a plan already authored by `/plan-doc` at `specs/NNN-<slug>/plan.md`, then hands the
finished work to `/finalize`. Follows the plan exactly; flags ambiguity instead of guessing.

## When to use this
- A `specs/NNN-<slug>/plan.md` exists with `status: authored`.
- Skip if no plan exists yet — run `/plan-doc` first.

## Procedure
1. Read the plan in full. Identify every deliverable. If the user named a plan, read it
   directly; otherwise take the one with `status: authored` from `specs/README.md` and confirm
   which to build.
2. **Work the plan's Steps in order, Do then Verify, one at a time.** On an ambiguous or
   conflicting step, stop and ask rather than guessing.
3. **Write tests alongside each unit**, matching the style already in the codebase (look at
   one existing test file first). Run them as part of that step's Verify.
4. **Close out via `/finalize`** — done-checks, changelog, version, plan-index flip to
   `implemented`, commit on confirm. Don't duplicate any of that here.

## What not to do
- Don't invent scope beyond the plan's Steps — new ideas go back to `/plan-doc`.
- Don't make architectural decisions mid-build — stop and ask.
- Don't skip a step's Verify because it "obviously works".
- Don't assert a function's return shape from memory — read it first. When the test is about
  *absence*, assert shape-independently (serialize the payload and search it).
