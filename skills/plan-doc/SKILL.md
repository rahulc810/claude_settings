---
name: plan-doc
description: Write or update a numbered plan in docs/plans/ and its index row. Use when the user asks to plan, design or spec work before building it, before calling ExitPlanMode on anything larger than a single edit, and when a plan's status changes to implemented, superseded or abandoned.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Plan doc

Writes a locked plan to `docs/plans/NNN-slug.md` and indexes it. `docs/plans/README.md`
sets the rules: numbered, append-only, written **before** the work, and the number is
kept forever. Status is tracked in the index table — never by renaming or deleting a file.

> **Orient first:** read the target repo's `CLAUDE.md` and its `docs/plans/README.md`
> header — they govern this repo's doc set, invariants and plan-status vocabulary, not
> devkit's.

## When to use this

- After `/planit` finalizes, to put the agreed plan on disk.
- On its own before `ExitPlanMode`, for anything bigger than a single edit.
- Skip for a one-file change nobody needs to re-read in six months.

## Steps

1. **Take the next number from the index, not from `ls`** — an abandoned plan still owns
   its number. `NNN-short-slug.md`, zero-padded, never reused.

   ```bash
   cat docs/plans/README.md
   ls docs/plans/
   ```

2. **Write the plan in the Files → Do → Verify shape.** Each step names the files it
   touches, the change, and how you will know it worked. This is the style already used
   across these repos; keep it.

   ```markdown
   # Plan NNN — <title>

   ## Context
   Why this work exists and what is currently true. Name the invariant or constraint that
   forced the design, not just the feature request.

   ## Decisions
   The choices that were actually contested, each with the reason it went that way. A
   reader six months from now needs the *why*, which the code will not carry.

   ## Steps

   ### 1. <imperative title>
   **Files:** `src/...`, `tests/test_....py`
   **Do:** the change, precisely enough to execute without re-deriving it.
   **Verify:** the command to run and the result that means success.

   ### 2. ...

   ## Out of scope
   What was deliberately left out, so it does not get re-litigated mid-build.
   ```

3. **Index it in the same change.** Add the row to the table in `docs/plans/README.md` —
   a plan file without an index row does not exist.

   | Status | Means |
   |---|---|
   | **authored** | written, not started |
   | **implemented** | landed — and there is a matching `docs/COMPLETE_ACTIONS.md` entry |
   | **superseded** | replaced — name the successor plan in the row |
   | **abandoned** | say why, in the row |

4. **Present it for approval *after* it's on disk**, referencing the file path. Plans here
   go through several rounds before approval; on disk, a revision is an edit rather than a
   rewrite from scratch.

## What not to do

- Don't flip a row to **implemented** yourself — that's `land-feature`'s job, so the
  status and the ledger entry it claims exists land together.
- Don't renumber, rename or delete a plan file to reflect a status change.
- Don't write a plan whose Verify lines can't actually be run.
