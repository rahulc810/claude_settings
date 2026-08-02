---
name: designit 
description: Iteratively drill a feature, idea or requirement into a locked high level design, then hand it to /plan-doc. Use when something needs designing and deciding before any code is written.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Designit

Starts from a single high-level plan and progressively zooms in, one round at a time,
until the details are locked. **No coding** — the output is a decision, not an
implementation.

## When to use this

- Before building anything whose shape isn't already obvious.
- Skip for a change you could describe fully in one sentence — go straight to the edit,
  or to `/plan-doc` if it still deserves a record.

## Steps

1. **State your assumptions upfront**, and ask clarifying questions rather than guessing
   at anything that would change the design.
2. **Draft the plan at one level of detail**, then present it and stop. The user decides:
   **redo** / **confirm and continue** (zoom in one level) / **confirm and finalize**.
3. **Repeat** until "confirm and finalize". Each round should add real resolution —
   structure, architecture, module boundaries, libraries, the decisions and their
   reasons — not restate the last one.
4. **Hand the finalized plan to `/plan-doc`**, which writes it to `docs/plans/NNN-slug.md`
   and indexes it. Only after "confirm and finalize".

## The finalized plan must carry

This is exactly what `/plan-doc` writes to disk — produce it in that shape so the handoff
is a copy, not a rewrite:

- **Context** — why the work exists, what is currently true, and the invariant or
  constraint that forced the design.
- **Decisions** — the choices that were actually contested, each with the reason it went
  that way.
- **Steps** — each with **Files** (what it touches), **Do** (the change, precisely enough
  to execute without re-deriving it) and **Verify** (the command, and the result that
  means success).
- **Out of scope** — what was deliberately left out, so it isn't re-litigated mid-build.

## What not to do

- Don't write code, and don't edit the target files "to check" — read only.
- Don't advance a round without the user's explicit word; "looks good" on one level isn't
  approval of the next.
- Don't leave a Step whose Verify can't actually be run.
