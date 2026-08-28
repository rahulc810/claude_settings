# Constitution

The pipeline's always-on rules. Every core skill reads this file as its first
Procedure step. Keep it under 60 lines — it loads on every skill run.

## Artifact ledger

The pipeline is a DAG the human walks. A skill starts when its input artifact exists at
a ready status — regardless of what ran last. To send work backward, drop the upstream
artifact's status and re-invoke its skill. "Stage" names are descriptive; a stage may
hold more than one skill (review = code-review, optionally improve / security-review).

| Artifact | Producer | Ready at | Consumed by |
|---|---|---|---|
| `CODEBASE.md`                | crawl          | fresh      | any skill |
| `specs/NNN-<slug>/spec.md`   | designit       | `accepted` | plan-doc |
| `specs/NNN-<slug>/plan.md`   | plan-doc       | `authored` | implement, code-review |
| `specs/NNN-<slug>/review.md` | code-review    | `open` / `closed` | resolve-review / finalize |
| `specs/NNN-<slug>/gates/*`   | any skill      | `answered` | the skill that parked |

## Status vocabularies

- spec:   `draft` → `accepted` → `superseded`
- plan:   `authored` → `implemented` → `superseded` → `abandoned`
- review: `open` → `worked-on` → `closed`
- gate:   `awaiting-input` → `answered` → `consumed`

Every artifact opens with `status:` and `updated:` (YYYY-MM-DD).

## Kickback

A downstream skill finds an upstream flaw:
- minor — edit the upstream artifact in place, revert its status (`accepted`→`draft`;
  a plan stays `authored`), bump `updated:`, re-invoke its skill.
- fundamental — the upstream skill writes NNN+1 that `supersedes` NNN.

## Item-execution loop

`implement` and `resolve-review` share this. Work the list (plan Steps / review Findings)
one item at a time: state the change in a sentence, apply it, run its Verify, then take
the next. If an item is bigger or wronger than written, stop — don't guess or widen
scope: flag it, or park a gate, and wait. End with a per-item summary: done /
skipped-with-reason / deferred.

## Gate protocol

A skill needing a human decision writes `specs/NNN-<slug>/gates/NNN-<gate>.md`
(`status: awaiting-input`) and stops. It resumes on `status: answered`, acts on
`response:`, then sets `consumed`. Interactive skills (designit, plan-doc, grill) get
the answer in-session; long-running skills (implement, resolve-review) actually park.

## Hard rules

1. No skill invokes another. The human — later, the orchestrator — drives every transition.
2. Files are canonical. Stores (MCP: brief, erp, wiki) are a mirror-only projection,
   except `specs/*/gates/*`, which the bridge may write back to.
3. An artifact at its path with a ready `status:` is the only "produced" signal.
