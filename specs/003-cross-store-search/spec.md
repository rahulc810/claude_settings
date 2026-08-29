status: accepted
updated: 2026-08-29

# Cross-store fuzzy search — one MCP endpoint over tasks, notes, briefs and wiki

## Problem

Four stores hold the context a session needs to orient itself: erp tasks, erp notes,
bridge briefs, and the wiki. They are queried through three separate MCP servers with
three unrelated search primitives:

| Store | Server | Backing | Search today |
|---|---|---|---|
| tasks, notes, comments | `mcp-erp` (uid 966) | `tasker.db` in `/var/lib/erp-app` | `list_tasks(search=)` / `list_notes(search=)` — SQL substring |
| briefs | `mcp-brief` | markdown in `bridge_shared_dir` | **none** — only `list_briefs` |
| wiki docs + entities | `mcp-wiki` (uid 962) | markdown in `/var/lib/mcp-wiki` | `search()` — unranked line-by-line `in` scan |

The consumer is the `/resume` skill. Its store sweep costs four batched tool calls, each
returning full rows, after which the *model* does the dedupe and ranking. That is the
cost: round-trips the harness pays for, plus token-expensive raw rows, plus ranking work
done by an LLM that a few milliseconds of local Python does better and for free.

Every match is also literal. `/resume` step 1 works around this by instructing the model
to supply synonyms per sweep, because `dnsmasq` and `dnsmaq` are two different strings to
all three stores.

## Goals

- One MCP call replaces the four-store sweep.
- Ranking, snippet extraction and dedupe keys computed server-side, not by the model.
- Typo- and morphology-tolerant matching (`dnsmaq` finds `dnsmasq`).
- Bodies are scanned but never returned whole — briefs and task descriptions are chatty.
- Each result row carries its own follow-up call, so the model does not infer a tool
  name per store.
- No existing tool changes behaviour.

## Non-Goals

- Write access of any kind. The endpoint is read-only across all four stores.
- Any index or cache — see Design.
- Embeddings or semantic search.
- Any change to `mcp-wiki` or `mcp-brief` source.
- Removing or altering the existing per-store `search=` params or `wiki-local search`.
- Returning full item bodies.
- Semantic synonym expansion (`dnsmasq` → `DHCP`). Deferred; see Open Questions and erp
  task #167.

## Considered Approaches

### Option A — new `mcp-search` container
A fourth container with read-only mounts of all four data dirs, own uid, own tool
namespace. Clean ownership boundary. Costs a new deploy unit, a new `services:` entry, a
new auth path, and read-coupling to three on-disk formats anyway.

### Option B — search tool inside `mcp-erp`
`mcp-erp` already mounts `/var/lib/erp-app` (tasks, notes) *and* `bridge_shared_dir`
(briefs) — three of the four stores, today, with no change. Add the wiki as a fourth
read-only mount. Zero new deploy units, zero new auth surface. Costs: the erp server
becomes the owner of wiki and brief knowledge (a boundary smear), and it bends erp's
domain-isolation invariant.

### Option C — fan-out aggregator
One tool that HTTP-calls the other two servers' search tools. No storage-format coupling.
Costs container-to-container auth tokens, three server-side hops per query, and briefs
have no search primitive to call — one would have to be written regardless. Worse, it
would fuzzy-match over `mcp-wiki`'s already-lossy unranked line output.

### Option D — shared FTS5 index
Each server writes to a common index on mutation; one reader queries it. Best query
quality. Costs a write-path coupling into three codebases and introduces a silent
staleness failure mode — a stale index returns confidently wrong answers.

## Decision

**Chosen:** Option B — a `search_all` tool inside `mcp-erp`, with the wiki added as a
read-only shared mount.

**Reason:** it is the only option that gets the one-round-trip win without touching any
existing server's write path or adding a deploy unit. erp is already a control-plane
application that sees three of the four stores; the fourth is one mount away. C and D
were rejected outright — C multiplies hops to consume a worse primitive, and D trades a
silent-staleness failure mode for query quality this corpus does not need. A was the
principled alternative and remains the fallback if erp's tool surface later becomes
crowded enough to justify a split.

## Design

### Placement

New module `erp/services/search.py`; new tool `search_all` in `erp/mcp_tasker/tools.py`.

Named `search`, not `fuzzy` — `fuzzy` already means date parsing in this repo
(`services/dates.parse_fuzzy_date`, `tests/test_fuzzy_routes.py`).

**Invariant exemption (erp CLAUDE.md invariant 3, "domains are isolated").** Recorded
here so it is not rediscovered as a bug:

> `search` is a read-only projection domain. It owns no schema and no DB file, imports no
> other `services/` module, and only ever reads. Its four store adapters are private to it.

### Adapters and record shape

Four adapters produce one uniform record:

```
Hit = {kind, id, title, date, status, thread, snippet, ref, score}
  kind = task | note | brief | wiki
```

| Adapter | Source | Fields read |
|---|---|---|
| task | `tasker.db` connection, read-only | `title`, `description`, `tags`, `thread`, `category`, `status`, `updated_at` |
| note | same connection | `title`, `body`, `tags`, `thread`, `archived_at`, `updated_at` |
| brief | `devkit.bridge.storage` | frontmatter (`title`, `status`, `thread`, `updated_at`) + body |
| wiki | `WIKI_ROOT` markdown tree | path, headings, body; `entities.md` rows as their own records |

`thread` is exposed deliberately: erp tasks, notes and briefs already share one thread
vocabulary, which gives `/resume`'s dedupe a real key instead of title-similarity
guessing. Wiki hits carry `thread: None`.

`ref` is a literal next call — `get_task(167)`, `get_note(12)`, `get_brief('b-…')`,
`get_doc('machines/fujitsu.md')`, `get_entity('fujitsu')`. This is the core of the
design: a row tells the model its own follow-up.

**Wiki granularity is one record per `##` section, not per file.** A whole host doc as one
record would score a blended average over unrelated halves and snippet from the wrong one.
Section-level yields `title: "fujitsu — DNS/DHCP"` with `ref: get_doc('machines/fujitsu.md')`.

**Devkit dependency.** `services/briefs.py` already imports `devkit.bridge.storage`, but
the needed enumerator, `storage._read_all`, is private. Add a public
`iter_briefs(data_dir)` to devkit — purely additive, but a public-signature change, so it
runs through `/devkit-api-change`. The alternative (re-reading the brief directory in
erp's adapter) duplicates a frontmatter parser and was rejected.

### No index — scan per call

erp invariant 2 forbids module-level global state, which rules out a cached in-process
index. That constraint is welcome here. The whole corpus is low single-digit MB; a full
scan-and-score is single-digit milliseconds. No invalidation logic, no drift, nothing that
can go silently stale. Signature stays a pure function:

```python
def search(conn, *, bridge_dir, wiki_root, query, kinds=None,
           limit=15, include_archived=False) -> list[Hit]
```

If measurement later shows the wiki tree has grown enough to hurt, that is the moment to
add an index — not before.

### Scoring

Each record flattens to two scored strings:

```
head = title + tags + thread + category + (wiki: path + headings)
body = description | note body | brief body | doc text
```

Scoring them separately is what stops a 4 KB brief body from outranking a task whose title
is an exact match.

Query splits on whitespace. Per term, take the maximum signal:

| Signal | Weight |
|---|---|
| exact token in `head` | 100 |
| substring in `head` | 85 |
| `rapidfuzz.fuzz.token_set_ratio` vs `head`, floor 70 | 0.7 × ratio |
| exact token in `body` | 45 |
| substring in `body` | 35 |
| `partial_token_set_ratio` vs `body`, floor 80 | 0.3 × ratio |

Average across terms, so an all-terms match beats a one-term match. Then apply:

- **Recency** ×1.0 → ×1.25, linear over `updated_at` within 90 days. A tiebreak only —
  deliberately too weak to float a stale irrelevant row above a fresh exact hit.
- **Status penalty** ×0.6 for `done`/`cancelled` tasks and archived notes, ×0.5 for
  `superseded` briefs. Demoted but present: "what did we decide about X" often lands on a
  closed item.
- **No kind weighting.** Weighting wiki up (durable) or briefs up (in-flight) are both
  query-dependent guesses; `kinds=` lets the caller be explicit instead.

Cut below 30. Sort by score desc, then `updated_at` desc.

These constants are a starting point, not a derivation. The test corpus is what moves them,
which is why the tests assert orderings rather than scores.

Snippet: the best-matching line, trimmed to ~160 chars.

Fuzzy library: `rapidfuzz`, one new pinned dependency in `erp/requirements.txt`. A compiled
wheel with no transitive baggage. Stdlib `difflib` works but is far slower and has no
token-set scorer.

### Tool surface

`search_all(query, kinds=None, limit=15, include_archived=False)` in
`mcp_tasker/tools.py`. Every existing tool is untouched.

### Deployment — the uid 962 / uid 966 problem

`mcp-wiki` runs as uid 962 and `mcp-erp` as uid 966, in separate rootful containers with
no userns remap. **A mount alone does not grant the read.** Measured locally with podman
5.8.2 under SELinux Enforcing, reproducing the box's uid/label/mount arrangement:

| # | Setup | Result |
|---|---|---|
| A | uid 966, no group-add, dir `2750 962:961` | Permission denied — the bare-mount state |
| B | uid 966, `--group-add 961` | READ=OK |
| C | B with `:z,ro` | WRITE=DENIED — `ro` composes with `z` |
| D | B, but file still `962:962 0640` | **Permission denied** |
| E | D with file `0644` | READ=OK |
| F | new file by uid 962, setgid dir, `--umask=002` → `962:961 0664` | READ=OK |

**Finding D is the trap.** `shared_groups.yml` sets the directory setgid but does not
descend. Every wiki doc that already exists keeps group `mcp-wiki` and stays unreadable to
uid 966 regardless of the mount — the wiki adapter would return zero hits, silently, on a
deploy that looks correct. A one-time recursive `chgrp` of existing wiki content is part of
this change, not an afterthought.

SELinux behaves: `:Z` assigns a fresh private MCS category on every run, but
`app.container.j2` derives the label from the mount count across all units, so adding a
second mounter flips **both** units to shared `z` at once. One relabel from private
category to `s0` at next start, then stable. No thrash.

Use the existing `shared_state_dirs` mechanism rather than a bespoke mount — it already
solves exactly this for `/var/lib/erp-app` between uid 971 and uid 966:

```yaml
  - path: /var/lib/mcp-wiki
    owner: mcp-wiki
    group: wikidata
    gid: 961          # 962 is mcp-wiki's own uid/gid; 963/964 taken. Pinned; fails loud on collision.
    members: [mcp-wiki, mcp-erp]
```

plus a `mounts:` entry on `mcp-erp` for `/var/lib/mcp-wiki`, plus `WIKI_ROOT=/var/lib/mcp-wiki`
in its `env:`.

**One template gap.** `roles/app/templates/app.container.j2` discards `m.opts` whenever a
path is shared:

```jinja
Volume={{ m.src }}:{{ m.dest }}:{{ 'z' if (...) > 1 else m.opts | default('Z') }}
```

so `opts: "ro,z"` cannot be expressed on a shared path and `mcp-erp` would get read-write
on the wiki. Reinterpreting `opts` is unsafe because existing entries already carry the
*label* there (`opts: z`), which would render as `z,z`. Add a separate boolean instead:

```yaml
mounts:
  - src: /var/lib/mcp-wiki
    dest: /var/lib/mcp-wiki
    read_only: true
```

templated as `…:{{ label }}{{ ',ro' if m.read_only | default(false) }}`. Additive; no
existing entry changes meaning.

`shared_groups.yml` hardcodes mode `2770` (group-write). With `read_only: true` the mount
layer blocks writes (test C), so 2770 is accepted as-is. Defence is one layer, not two;
narrowing to `2750` for read-only members is a second template change and is out of scope.

### Consumer — `/resume`

Rewriting `/resume` is in scope for this spec's plan. The tool without its consumer is half
the change.

- Step 2 collapses from four batched calls to one `search_all(query, limit=15)`.
- Step 3 becomes "collapse rows sharing a `thread`" — ranking is server-side now.
- Step 1 keeps its synonym instruction until erp task #167 lands.
- Step 5's per-kind reads are unchanged, now driven by `ref`.
- `allowed-tools` drops four entries and adds `search_all`.

### Tests — `erp/tests/test_search.py`

- **Adapters:** each of the four against a fixture store. `tmp_path` wiki tree and brief
  dir; `ERP_DB_DIR` from `mktemp -d`, never `~/databases`.
- **Ranking, asserted as orderings not scores:** exact title hit outranks body hit; fresh
  outranks stale at equal match; a `done` task is demoted below an open one; a 4 KB brief
  body does not outrank a matching task title.
- **Fuzzy:** `dnsmaq` finds `dnsmasq`; reordered/partial `masq dns` finds it; `DHCP` does
  **not** — asserted as a known gap pointing at #167, so the limitation lives in the suite
  rather than being rediscovered.
- **Isolation:** `search.py` imports no other `services/` module (grep assertion; guards
  invariant 3).
- **Edges:** empty query, no hits, `kinds=` filtering, `limit` honoured.

### Pre-flight, on the box, before deploy

`find /var/lib/mcp-wiki ! -group wikidata | head` after the recursive chgrp, plus a positive
read as uid 966. The wiki adapter must raise a "wiki root unreadable" error rather than
return an empty list — an all-absent derived result is a failing parser until proven
otherwise, and a silently wiki-less search is the worst outcome this design can produce.

## Open Questions

- **Scoring constants.** The weights, the 70/80 fuzzy floors, the 30 cutoff and the 1.25
  recency ceiling are starting points. Expect the test corpus to move them; the tests are
  written so it can.
- **Semantic synonyms.** Fuzzy matching fixes typos, morphology and word order — it will
  never bridge `dnsmasq` → `DHCP` or `fujitsu` → `.115`. Deferred to **erp task #167**
  (thread `erp-search`): ship fuzzy-only, observe which real queries miss, then build a
  small static alias table from observed misses rather than guessing the set up front.
  Embeddings were rejected as breaking the cheap-static-local-compute premise.
- **Live box state unverified.** The uid/mount findings above are a faithful local
  reproduction; SSH to 192.168.1.115 was blocked during design. The actual file modes under
  `/var/lib/mcp-wiki` must be checked by the pre-flight before the deploy is trusted.
