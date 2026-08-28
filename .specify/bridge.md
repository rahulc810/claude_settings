status: draft
updated: 2026-08-28

# Bridge adapter — spec only

The optional file↔store adapter. **Not built here** — this is the contract the
orchestrator phase implements. Absent the adapter, the pipeline is unaffected: gates are
answered at the terminal and every artifact stays a local file.

Files are canonical (constitution, hard rule 2). The bridge is a mirror-only projection
outward, with one narrow exception written back: `specs/*/gates/*`.

## Outward (mirror only)

Watch, on the repo:

- `specs/*/gates/*.md` with `status: awaiting-input`
- the plan `status:` line in each `specs/*/plan.md` and its `specs/README.md` row

On a change, push a representation to a store (an `erp` task or a `brief` thread):

- payload = artifact path + `status:` + for a gate, its `## Question` and `## Options`
- the store copy is a notification, never a source of truth; nothing reads it back
  except the inward path below

## Inward (the one write-back)

A store reply to a mirrored gate resolves to **exactly one** gate file (by the path in
the payload). The adapter writes into that file only:

- `response:` ← the reply text, verbatim
- `status:` ← `answered`, and bump `updated:`

Nothing else in the repo is touched. The skill that parked on the gate consumes it
(`status: consumed`) on its next run — the adapter never advances the pipeline.

## Idempotent

Re-running the adapter over a gate already at `status: answered` or `consumed` is a
no-op. A store reply that arrives twice writes the same `response:`/`answered` and is
harmless. The outward mirror is upsert-by-path.

## Out of scope for the adapter

- Advancing plan/review status (only the skills do that).
- Any write outside `specs/*/gates/*`.
- Running when no store is configured — it simply does not start.
