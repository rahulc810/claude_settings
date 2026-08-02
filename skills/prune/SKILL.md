---
name: prune
description: Condense the repo's markdown docs back to their conventions — compress the ledger, archive old plans, delete outdated content. Use for periodic housekeeping when the docs have crept.
disable-model-invocation: true
allowed-tools: Read, Edit, Bash
---

# Prune

Condenses the markdown docs and puts them back on convention. Git is the real archive —
nothing here is lost by being cut.

## When to use this

- Periodic housekeeping; not gated on any other skill finishing.
- Skip if the docs are already within the thresholds below — the checks are cheap, the
  rewrites are not.

## Each doc's job

| File | Holds |
|---|---|
| `README.md` | how to run it |
| `CLAUDE.md` | invariants |
| `docs/COMPLETE_ACTIONS.md` | append-only log |
| `docs/plans/*` | `NNN-short-slug.md`, zero-padded, never reused — `NNN` is the chronological id |

Content in the wrong file gets moved to the right one, not deleted.

## Steps

1. **Survey before proposing.** Line counts, plan count, and any file that doesn't match
   the naming convention.

   ```bash
   wc -l README.md CLAUDE.md docs/COMPLETE_ACTIONS.md
   ls docs/plans/
   ```

2. **Apply the thresholds.**
   - `docs/COMPLETE_ACTIONS.md` over 300 lines → compress everything older than the last
     3 entries to one line per entry. Never drop an entry entirely.
   - More than 10 plans in `docs/plans/` → move the oldest to `docs/plans/archive/`,
     leaving open and unstarted plans where they are. The index row stays in
     `docs/plans/README.md`; archiving is not a status change.
   - Any plan not named `NNN-short-slug.md` → rename it and update every reference in the
     other markdown files.

3. **Remove what's redundant or outdated** — content the code now contradicts, or that a
   later entry supersedes.

4. **Remove closed reviews** - from `docs/reviews/` with closed status.

5. **Present the proposed actions as a list and get confirmation before touching
   anything.** This skill rewrites history-shaped files; it doesn't do that unasked.
  

## What not to do

- Don't delete a `COMPLETE_ACTIONS` entry or a plan file — compress and archive instead.
- Don't renumber a plan, ever, including an abandoned one.
- Don't move content into `CLAUDE.md` that isn't an invariant; it is not a changelog.
