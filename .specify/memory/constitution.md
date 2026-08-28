# Constitution

The pipeline's always-on rules. Every core skill reads this file as its first
Procedure step. Keep it under 60 lines — it loads on every skill run.

## Pipeline map

| Stage | Skill | Produces | Next |
|---|---|---|---|
| orient  | crawl          | `CODEBASE.md`                 | designit |
| design  | designit       | `specs/NNN-<slug>/spec.md`    | plan-doc |
| plan    | plan-doc       | `specs/NNN-<slug>/plan.md`    | implement |
| build   | implement      | code                         | code-review |
| review  | code-review    | `specs/NNN-<slug>/review.md`  | resolve-review |
| fix     | resolve-review | (updates `review.md` status) | code-review |
| land    | finalize       | commit                       | — |

## Status vocabularies

- spec:   `draft` → `accepted` → `superseded`
- plan:   `authored` → `implemented` → `superseded` → `abandoned`
- review: `open` → `worked-on` → `closed`
- gate:   `awaiting-input` → `answered` → `consumed`

## Artifact header

Every pipeline artifact opens with two lines:

    status: <one value from its vocabulary>
    updated: YYYY-MM-DD

A downstream skill starts only when the upstream artifact exists at its path with a
ready status — `accepted` (spec), `authored` (plan), `closed` (review).

## Gate protocol

A skill that needs a human decision writes `specs/NNN-<slug>/gates/NNN-<gate>.md` with
`status: awaiting-input`, then stops — no held process. It resumes (via `/resume` or
re-invocation) once that file reads `status: answered`, acts on `response:`, then sets
`status: consumed`. Interactive skills (designit, plan-doc, grill) normally get the
answer in-session and the file is just the record; long-running skills (implement,
resolve-review) actually park.

## Hard rules

1. No skill invokes another. The human — later, the orchestrator — drives every transition.
2. Files are canonical. Stores (MCP: brief, erp, wiki) are a mirror-only projection,
   except `specs/*/gates/*`, which the bridge may write back to. Pull every store and
   the pipeline still runs.
3. An artifact at its path with a ready `status:` is the only "produced" signal. No
   ledger, no separate index of pipeline state.
