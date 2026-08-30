# Skills workflow

A map, not a skill. Nothing here fires automatically — each step is invoked by hand.
The always-on rules and status vocabularies live in `.specify/memory/constitution.md`;
this file is the human-facing map on top of it.

## Two invariants

1. **No skill calls another.** You decide when to move from one step to the next — later,
   an orchestrator may, but nothing else.
2. **Files are canonical.** Each step hands off by leaving an artifact at a known path
   with a ready `status:`; the next step reads it. No wrapper, no ledger of pipeline state.

## The pipeline

```
grill            → pressure-test the idea first (no artifact)
crawl            → CODEBASE.md                          (orient)
   ↓
designit         → specs/NNN-<slug>/spec.md      status: accepted
   ↓
plan-doc         → specs/NNN-<slug>/plan.md       status: authored   + row in specs/README.md
   ↓
implement        → code + tests, one step at a time
   ↓
code-review      → specs/NNN-<slug>/review.md     status: open
   ↕ (loop until closed)
resolve-review   → fixes, review.md               status: worked-on
   ↓ (code-review running-review → status: closed)
finalize         → done-checks, version, commit; flips plan row to implemented
```

Human decision points (designit rounds, plan-doc review gate, implement ambiguity) use
the constitution's **gate protocol**: write `specs/NNN-<slug>/gates/NNN-<gate>.md`,
`status: awaiting-input`, stop; resume on `status: answered`.

`notice` runs continuously alongside all of the above. `diagnose`, `prototype`,
`improve` are reached for mid-work, off the chain.

## Core

The portable unit — identical on every machine. Copying `.specify/` + the 12 core
`skills/` dirs + the authoring-standard section of `skills/README.md` to another machine
yields a working pipeline with no edits.

`crawl` · `designit` · `plan-doc` · `implement` · `code-review` · `resolve-review` ·
`finalize` · `diagnose` · `improve` · `prototype` · `grill` · `notice`

## Overlay

This setup's domain — devkit / erp / brief-mcp. Not portable; a partner's pipeline
carries its own overlay (or none).

`land-feature` (devkit ledger over `finalize`) · `devkit-api-change` · `query-db` ·
`handoff` · `resume` · agents `consumer-impact` · `ledger` · `verifier`

## Utility

General, off the linear pipeline.

`prune` (docs + skill-registry housekeeping) · `forge` (idea→skill assessor) ·
`prototype-ui` · `postmortem` · `teachme` · `tldr` · `yt-notes` · `yt-tldr` ·
agent `skeptic`

## When each fires

- **`grill`** — explicit, before `designit`, when reasoning needs pressure-testing.
- **`designit`** — explicit, when a feature/idea needs drilling before building.
- **`plan-doc`** — after `designit` finalizes, or on its own before `ExitPlanMode` for
  anything bigger than a single edit.
- **`implement`** — when a `specs/*/plan.md` is `authored`.
- **`code-review` / `resolve-review`** — after a build, before landing. `code-review`
  reports and never fixes; `resolve-review` fixes and never closes.
- **`finalize`** — when the review thread is `closed`. `land-feature` is its devkit overlay.
- **`diagnose`** — the stance to hold whenever debugging; not a step.
- **`prototype` / `prototype-ui`** — mid-build, to prove an approach before committing.
- **`prune`** — periodic housekeeping on docs and the skill registry.
- **`forge`** — explicit, when `docs/skill-ideas/` has accumulated, or pointed at an
  external skill set to assess it. It is `notice`'s downstream.
- **`notice`** — no trigger, just habit.

## Reading long markdown

`scripts/mdreader.html` — open it in a browser, drag a folder onto the window (or click
**Open folder**). Folder tree left, one slide at a time in the middle, section outline
right; `←` `→` to page, `Alt+←` to go back. It reads the markdown live off disk, so it is
never stale, and it is coupled to nothing — any folder works. See `specs/004-md-navigation/`.
