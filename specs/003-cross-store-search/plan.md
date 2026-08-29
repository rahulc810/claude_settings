status: implemented
updated: 2026-08-29
spec: specs/003-cross-store-search/spec.md

# Plan 003 — cross-store fuzzy search (`search_all`)

## Context

Four stores hold session context — erp tasks, erp notes, bridge briefs, wiki docs — behind
three MCP servers with three unrelated search primitives. `/resume` sweeps them in four
batched calls, gets back full rows, and makes the *model* rank and dedupe.

What is true in the code today:

- `erp/mcp_tasker/tools.py` registers ~25 tools, each a thin wrapper that opens
  `get_connection(TASKER_DOMAIN)` and calls a pure `services/` function. It already imports
  `devkit.bridge.storage` (via `services/briefs.py`) and resolves the brief store with a
  local `_bridge_dir()` helper (`db.resolve_db_dir("BRIEF_DATA_DIR", …)`).
- `services/tasker.list_tasks` and `services/notes.list_notes` take a `search=` kwarg that
  compiles to SQL `LIKE %…%`. Literal substring, no ranking.
- `devkit.bridge.storage.list_briefs` returns **metadata only** — no body. The only
  full-corpus enumerator is `storage._read_all`, which is private.
- `mcp-wiki` is a separate repo and a separate container; erp cannot import it. The wiki is
  plain markdown under `WIKI_ROOT`, with `entities.md` as a markdown table.
- `server-scripts/group_vars/all.yml` gives `mcp-erp` uid 966 and mounts `/var/lib/erp-app`
  (tasks, notes) plus `bridge_shared_dir` (briefs). `mcp-wiki` is uid 962 and shares
  nothing.

Forced constraints: erp invariant 2 (services are pure functions, no module-level state)
rules out a cached index; erp invariant 3 (domains isolated) is bent by a cross-store
reader, so the exemption is written down rather than discovered later. The uid 962/966
interaction was measured locally with podman under SELinux Enforcing during `/designit` —
those findings drive steps 10–12.

## Decisions

1. **Search lives in `mcp-erp`, not a new container.** It already sees three of four
   stores; the wiki is one mount away. Zero new deploy units, zero new auth surface.
2. **No index, scan per call.** Corpus is low single-digit MB. Removes invalidation logic
   and the silent-staleness failure mode, and keeps `search()` a pure function.
3. **`rapidfuzz`, not `difflib`.** Needs a token-set scorer; `difflib` has none and is far
   slower.
4. **Two scored strings per record (`head`/`body`), not one.** Prevents a 4 KB brief body
   from outranking an exact task-title match.
5. **Wiki records are per `##` section, not per file.** A whole host doc scores a blended
   average over unrelated halves and snippets from the wrong one.
6. **`ref` is a literal call string** (`get_task(167)`), so the model never infers a tool
   name per store. This is the token win, not just the round-trip win.
7. **Named `search`, never `fuzzy`.** `fuzzy` already means date parsing in this repo
   (`services/dates.parse_fuzzy_date`, `tests/test_fuzzy_routes.py`).
8. **`read_only:` is a new mount key, not an `opts:` string.** Existing entries put the
   SELinux *label* in `opts:` (`opts: z`), so appending `ro` there would render `z,z`.
9. **Ranking tests assert orderings, not scores**, so the constants can be tuned without
   rewriting the suite.

## Out of Scope

- Any write path. `search_all` is read-only across all four stores.
- Any index, cache, or FTS5 table.
- Semantic synonym expansion — deferred to erp task **#167**.
- Changes to `mcp-wiki` or `mcp-brief` source.
- Changes to the existing `search=` params or `wiki-local search`.
- Narrowing `shared_groups.yml`'s hardcoded `2770` to `2750` for read-only members.
- The `COMPLETE_ACTIONS.md` entry and the erp version bump — `/finalize` owns those, so
  status and ledger land together.
- Committing anything in `claude_settings`, whose tree is currently dirty.

## Steps

### 1. Add a public brief enumerator to devkit

**Files**
- `/storage1/Documents/code/devkit/src/devkit/bridge/storage.py` — add public function
- `/storage1/Documents/code/devkit/tests/test_bridge_storage.py` — add test

**Do**
Add, directly after `list_briefs`:

```python
def iter_briefs(data_dir: Path | str) -> list[dict[str, str]]:
    """Every brief as a summary dict plus its ``body`` — the full-corpus read.

    ``list_briefs`` returns metadata only and ``get_brief`` reads one at a time;
    a consumer that needs to scan every body (search, export) has no public way
    to do it. Same shape as ``get_brief``, for every brief, newest id first.
    """
    out: list[dict[str, str]] = []
    for _path, meta, body in _read_all(data_dir):
        summary = _meta_to_summary(meta)
        summary["body"] = body.strip()
        out.append(summary)
    out.sort(key=lambda b: b["id"], reverse=True)
    return out
```

Purely additive — no existing signature changes. Add a test asserting `iter_briefs` returns
one entry per created brief, each carrying a non-empty `body`, ordered newest id first.

**Verify**
```bash
/storage1/Documents/code/erp/bin/pytest -q /storage1/Documents/code/devkit/tests/test_bridge_storage.py
```
Expected: all tests pass, count one higher than before the edit, `0 failed`.

---

### 2. Add the `rapidfuzz` dependency to erp

**Files**
- `/storage1/Documents/code/erp/requirements.txt` — add pin

**Do**
Append, with a comment matching the file's existing style:

```
# Fuzzy scoring for services/search.py (token-set + partial ratio). Compiled wheel,
# no transitive deps. NOT related to services/dates.parse_fuzzy_date.
rapidfuzz>=3.9,<4
```

Then install it into erp's venv.

**Verify**
```bash
/storage1/Documents/code/erp/bin/pip install -r /storage1/Documents/code/erp/requirements.txt \
  && /storage1/Documents/code/erp/bin/python -c "import rapidfuzz; print(rapidfuzz.__version__)"
```
Expected: a version string `3.x`, exit 0. (Before this step the same import raises
`ModuleNotFoundError: No module named 'rapidfuzz'`.)

---

### 3. Create `services/search.py` with the record shape and scoring core

**Files**
- `/storage1/Documents/code/erp/services/search.py` — new

**Do**
Module docstring must open with the invariant-3 exemption:

> `search` is a read-only projection domain. It owns no schema and no DB file, imports no
> other `services/` module, and only ever reads. Its four store adapters are private to it.

Define the constants (module-level, immutable — not state):

```python
W_HEAD_EXACT   = 100.0
W_HEAD_SUB     = 85.0
W_HEAD_FUZZ    = 0.7      # multiplier on token_set_ratio
W_BODY_EXACT   = 45.0
W_BODY_SUB     = 35.0
W_BODY_FUZZ    = 0.3      # multiplier on partial_token_set_ratio
FUZZ_FLOOR_HEAD = 70
FUZZ_FLOOR_BODY = 80
SCORE_CUTOFF   = 30.0
RECENCY_DAYS   = 90
RECENCY_MAX    = 1.25
PENALTY_CLOSED = 0.6      # done/cancelled tasks, archived notes
PENALTY_SUPERSEDED = 0.5  # superseded briefs
SNIPPET_CHARS  = 160
```

Define a `Record` dataclass (internal, not returned): `kind, id, title, date, status,
thread, head, body, ref`.

Add the pure scorers:

- `_terms(query: str) -> list[str]` — casefold, split on whitespace, drop empties.
- `_term_score(term, head, body) -> float` — the max of: `W_HEAD_EXACT` if `term` is a
  whole token of `head`; `W_HEAD_SUB` if a substring of `head`;
  `W_HEAD_FUZZ * fuzz.token_set_ratio(term, head)` when that ratio ≥ `FUZZ_FLOOR_HEAD`;
  and the three `body` equivalents using `fuzz.partial_token_set_ratio` /
  `FUZZ_FLOOR_BODY`. All comparisons casefolded.
- `_recency_factor(date_str) -> float` — 1.0 → `RECENCY_MAX`, linear over `RECENCY_DAYS`
  from `date_str`; 1.0 when unparseable or older.
- `_status_factor(kind, status) -> float` — `PENALTY_CLOSED` for task status in
  `{"done","cancelled"}` and for `kind == "note"` with status `"archived"`;
  `PENALTY_SUPERSEDED` for brief status `"superseded"`; else 1.0.
- `_score(record, terms) -> float` — mean of `_term_score` across terms, times both
  factors. Zero when `terms` is empty.
- `_snippet(record, terms) -> str` — the line of `body` (falling back to `head`) with the
  highest `_term_score`, whitespace-collapsed, truncated to `SNIPPET_CHARS` with a
  trailing `…` when cut.

No I/O in this step.

**Verify**
```bash
/storage1/Documents/code/erp/bin/python -c "
import sys; sys.path.insert(0,'/storage1/Documents/code/erp')
from services import search as s
print(s._term_score('dnsmasq','fujitsu dnsmasq dhcp',''))
print(s._term_score('dnsmaq','fujitsu dnsmasq dhcp',''))
print(s._term_score('zzzz','fujitsu dnsmasq dhcp',''))
"
```
Expected: three floats — `100.0`, a value strictly between `0` and `100` (the fuzzy hit),
then `0.0`.

---

### 4. Add the task and note adapters

**Files**
- `/storage1/Documents/code/erp/services/search.py` — extend

**Do**
Depends on step 3's `Record`.

`_tasks(conn) -> list[Record]` — `SELECT id, title, description, tags, thread, category,
status, updated_at FROM tasks`. Raw SQL in this module; **do not** import
`services.tasker`, which would break the isolation assertion in step 9.
- `head` = `title tags thread category` joined by spaces
- `body` = `description`
- `id` = `str(id)`, `date` = `updated_at[:10]`, `ref` = `f"get_task({id})"`

`_notes(conn, include_archived) -> list[Record]` — `SELECT id, title, body, tags, thread,
archived_at, updated_at FROM notes`; when `include_archived` is false, add
`WHERE archived_at IS NULL`.
- `head` = `title tags thread`, `body` = `body`
- `status` = `"archived"` if `archived_at` else `"active"`
- `ref` = `f"get_note({id})"`

**Verify**
```bash
/storage1/Documents/code/erp/bin/pytest -q /storage1/Documents/code/erp/tests/test_smoke.py
```
Expected: `0 failed` — confirms the new module imports cleanly under the app's fixtures and
nothing existing regressed.

---

### 5. Add the brief adapter

**Files**
- `/storage1/Documents/code/erp/services/search.py` — extend

**Do**
Depends on step 1's `iter_briefs`.

`_briefs(bridge_dir) -> list[Record]`, calling
`from devkit.bridge import storage as brief_store` then `brief_store.iter_briefs(bridge_dir)`.
Per brief: `head` = `title` + `thread`, `body` = `body`, `id` = the brief id,
`date` = `updated_at[:10]`, `status` = the brief's `status`,
`ref` = `f"get_brief({id!r})"`. Return `[]` when `bridge_dir` does not exist.

**Verify**
```bash
/storage1/Documents/code/erp/bin/python -c "
import sys; sys.path.insert(0,'/storage1/Documents/code/erp')
from services import search as s
print(s._briefs('/nonexistent/path'))
"
```
Expected: `[]`, exit 0.

---

### 6. Add the wiki adapter

**Files**
- `/storage1/Documents/code/erp/services/search.py` — extend

**Do**
`_wiki(wiki_root) -> list[Record]`.

Raise `SearchError("wiki root unreadable: <path>")` (a new module-level exception class)
when `wiki_root` exists but is not readable, or when it is readable but every `*.md` under
it fails to open. **Do not return `[]` in that case** — a silently wiki-less search is the
worst outcome this design can produce, and an all-absent derived result is a failing parser
until proven otherwise. Return `[]` only when `wiki_root` does not exist at all (local dev
without the mount).

For each `*.md` found recursively, excluding `entities.md`:
- Split the text on lines matching `^##\s+` into sections. Text before the first `##` is
  one section titled after the file stem.
- One `Record` per section: `title` = `f"{stem} — {heading}"`, `head` = relative path +
  heading, `body` = the section text, `id` = the root-relative path, `status` = `None`,
  `thread` = `None`, `date` = the file's mtime as `YYYY-MM-DD`,
  `ref` = `f"get_doc({relpath!r})"`.

For `entities.md`, parse the markdown table locally (a small private parser — erp cannot
import `mcp_wiki`) and emit one `Record` per row: `title` = the canonical name,
`head` = name + aliases + type, `body` = the row text, `ref` = `f"get_entity({name!r})"`.

**Verify**
```bash
/storage1/Documents/code/erp/bin/python -c "
import sys, tempfile, pathlib; sys.path.insert(0,'/storage1/Documents/code/erp')
from services import search as s
d = pathlib.Path(tempfile.mkdtemp()); (d/'machines').mkdir()
(d/'machines'/'fujitsu.md').write_text('intro line\n\n## DNS and DHCP\ndnsmasq runs here\n')
r = s._wiki(d)
print(len(r)); print([x.title for x in r]); print(r[-1].ref)
print(s._wiki(pathlib.Path('/nonexistent')))
"
```
Expected: `2`; a list containing `'fujitsu — DNS and DHCP'`;
`get_doc('machines/fujitsu.md')`; then `[]`.

---

### 7. Assemble `search()`

**Files**
- `/storage1/Documents/code/erp/services/search.py` — extend

**Do**
Depends on steps 3–6.

```python
def search(conn, *, bridge_dir, wiki_root, query, kinds=None,
           limit=15, include_archived=False) -> list[dict]:
```

Behaviour: return `[]` immediately when `_terms(query)` is empty. Build the record list
from whichever adapters `kinds` allows (`None` = all four; valid values `task`, `note`,
`brief`, `wiki`; an unknown value raises `ValueError`). Score every record, drop anything
below `SCORE_CUTOFF`, sort by score descending then `date` descending, truncate to `limit`.

Project each surviving record to the wire dict, in this key order:

```python
{"kind", "id", "title", "date", "status", "thread", "snippet", "ref", "score"}
```

with `score` rounded to `int`. `search` opens no connection of its own — `conn` is an
argument, per erp invariant 2.

**Verify**
```bash
/storage1/Documents/code/erp/bin/python -c "
import sys; sys.path.insert(0,'/storage1/Documents/code/erp')
from services import search as s
print(s.search(None, bridge_dir='/nonexistent', wiki_root='/nonexistent',
               query='', kinds=['brief']))
"
```
Expected: `[]`, exit 0 (empty query short-circuits before any adapter runs).

---

### 8. Register the `search_all` MCP tool

**Files**
- `/storage1/Documents/code/erp/mcp_tasker/tools.py` — add tool + helper

**Do**
Depends on step 7.

Add `from services import search as search_svc` to the imports, and a `_wiki_root()` helper
beside the existing `_bridge_dir()`:

```python
def _wiki_root():
    """Where the wiki tree is mounted read-only into this container (WIKI_ROOT)."""
    return Path(os.environ.get("WIKI_ROOT", "/var/lib/mcp-wiki"))
```

Register, in the Reads section after `get_distinct`:

```python
@mcp.tool()
def search_all(
    query: str,
    kinds: list[str] | None = None,
    limit: int = 15,
    include_archived: bool = False,
) -> list[dict]:
```

Docstring is the model-facing interface — state that it searches tasks, notes, briefs and
the wiki in one call, returns ranked shortlist rows (never full bodies), that each row's
`ref` is the literal follow-up call to read that item, that `thread` ties rows across
stores, and that matching is typo-tolerant but **not** synonym-aware, so distinct concepts
still need distinct terms.

Body opens `get_connection(TASKER_DOMAIN)` and calls
`search_svc.search(conn, bridge_dir=_bridge_dir(), wiki_root=_wiki_root(), query=query,
kinds=kinds, limit=limit, include_archived=include_archived)`.

Every existing tool is untouched.

**Verify**
```bash
/storage1/Documents/code/erp/bin/pytest -q /storage1/Documents/code/erp/tests/test_mcp_tasker.py
```
Expected: `0 failed`.

---

### 9. Write `tests/test_search.py`

**Files**
- `/storage1/Documents/code/erp/tests/test_search.py` — new

**Do**
Depends on steps 3–8. Use the existing `tasker_conn` fixture (already isolates `DB_DIR` to
`tmp_path`); build wiki and brief trees under `tmp_path`. Never touch `~/databases`.

Cover:

- **Adapters** — one test each for `_tasks`, `_notes`, `_briefs`, `_wiki` against a fixture
  store; assert record count and `ref` format.
- **Ranking, asserted as orderings not scores:**
  - a task whose *title* is an exact match ranks above one matching only in `description`;
  - at equal match quality, the row with the newer `updated_at` ranks first;
  - a `done` task ranks below an otherwise identical `pending` one;
  - a 4 KB brief body containing the term ranks below a task whose title is the term.
- **Fuzzy** — `dnsmaq` finds a `dnsmasq` record; reordered `masq dns` finds it; `DHCP` does
  **not** find a `dnsmasq`-only record. Mark that last one with a comment naming erp task
  **#167** so the known gap lives in the suite instead of being rediscovered.
- **Wiki failure mode** — a `wiki_root` that exists but is unreadable raises `SearchError`;
  a `wiki_root` that does not exist returns `[]`.
- **Isolation** — read `services/search.py` and assert no line matches
  `^from services import` or `^import services`, guarding erp invariant 3.
- **Edges** — empty query returns `[]`; no-hit query returns `[]`; `kinds=["wiki"]` returns
  only wiki rows; an unknown kind raises `ValueError`; `limit` is honoured.

**Verify**
```bash
/storage1/Documents/code/erp/bin/pytest -q /storage1/Documents/code/erp/tests/test_search.py
```
Expected: all tests pass, `0 failed`.

---

### 10. Add a `read_only` mount key to the quadlet template

**Files**
- `/storage1/Documents/code/server-scripts/roles/app/templates/app.container.j2` — edit the
  `Volume=` loop

**Do**
The current line derives the SELinux label but **discards `m.opts` on shared paths**, so
`ro` cannot be expressed there:

```jinja
Volume={{ m.src }}:{{ m.dest }}:{{ 'z' if (all_mount_srcs | select('equalto', m.src) | list | length) > 1 else m.opts | default('Z') }}
```

Append a separate, additive flag rather than reinterpreting `opts` (existing entries put
the *label* in `opts:`, so appending there renders `z,z`):

```jinja
Volume={{ m.src }}:{{ m.dest }}:{{ 'z' if (...) > 1 else m.opts | default('Z') }}{{ ',ro' if m.read_only | default(false) else '' }}
```

Add a comment above it recording why `read_only:` is its own key and not part of `opts:`.
No existing mount entry changes meaning — every one of them omits `read_only`.

**Verify**
```bash
/storage1/Documents/code/erp/bin/python -c "
import jinja2,sys
t=open('/storage1/Documents/code/server-scripts/roles/app/templates/app.container.j2').read()
jinja2.Environment().parse(t); print('template parses')
"
```
Expected: `template parses`, exit 0.

---

### 11. Declare the wiki as a shared state dir and mount it into `mcp-erp`

**Files**
- `/storage1/Documents/code/server-scripts/group_vars/all.yml` — `shared_state_dirs` and the
  `mcp-erp` service entry

**Do**
Depends on step 10.

Append to `shared_state_dirs`:

```yaml
  - path: /var/lib/mcp-wiki
    # mcp-erp reads the wiki for search_all (spec 003). gid 961 continues the
    # descending block: 962 is mcp-wiki's own uid/gid, 963/964 are taken. Pinned,
    # so a collision fails the task loudly rather than drifting.
    owner: mcp-wiki
    group: wikidata
    gid: 961
    members: [mcp-wiki, mcp-erp]
```

In the `mcp-erp` entry, add to `env:`:

```yaml
      WIKI_ROOT: /var/lib/mcp-wiki
```

and to `mounts:`:

```yaml
      # Read-only: mcp-erp searches the wiki, mcp-wiki owns it. The `z` label is
      # derived (two units now mount this path); `read_only` is the DAC/mount half.
      - src: /var/lib/mcp-wiki
        dest: /var/lib/mcp-wiki
        read_only: true
```

Measured basis (podman 5.8.2, SELinux Enforcing, `/designit` session): the mount alone gives
uid 966 `Permission denied`; `GroupAdd` of the shared gid is what grants the read; `z` and
`ro` compose; and the template derives `z` for *both* units at once, so there is no
label thrash.

**Verify**
```bash
/storage1/Documents/code/server-scripts/../erp/bin/python -c "
import yaml
d=yaml.safe_load(open('/storage1/Documents/code/server-scripts/group_vars/all.yml'))
print([s['gid'] for s in d['shared_state_dirs']])
e=[s for s in d['services'] if s['name']=='mcp-erp'][0]
print(e['env']['WIKI_ROOT'])
print([m for m in e['mounts'] if m['src']=='/var/lib/mcp-wiki'])
"
```
Expected: a gid list containing `961` with no duplicates; `/var/lib/mcp-wiki`; and one
mount dict with `read_only: True`.

---

### 12. Re-group existing wiki files so the shared group actually grants read

**Files**
- `/storage1/Documents/code/server-scripts/roles/app/tasks/shared_groups.yml` — add a task

**Do**
Depends on step 11. **This is the step that decides whether the feature works at all.**

`shared_groups.yml`'s existing directory task uses `state: directory`, which does not
descend, so setgid fixes only *new* files. Measured: a wiki doc left at `mcp-wiki:mcp-wiki
0640` is unreadable to uid 966 even with the group membership and the mount correct — the
wiki adapter would return zero hits silently on a deploy that looks green.

Add, after the existing "Create/adjust the shared directories" task, a recursive re-group
that runs only where existing content predates the shared group:

```yaml
# state: directory above does not descend, so files created BEFORE the shared group
# existed keep their old group and stay unreadable to the second member — measured,
# not theoretical (spec 003). recurse re-groups them once; it is idempotent.
- name: Re-group existing files under the shared directories
  ansible.builtin.file:
    path: "{{ item.path }}"
    state: directory
    group: "{{ item.group }}"
    recurse: true
  loop: "{{ shared_state_dirs }}"
  loop_control:
    label: "{{ item.path }}"
```

Note `recurse: true` with no `mode:` — setting a mode here would recursively clobber file
permissions across `/var/lib/erp-app` and the bridge tree. Group only.

**Verify**
```bash
/storage1/Documents/code/erp/bin/python -c "
import yaml; d=yaml.safe_load(open('/storage1/Documents/code/server-scripts/roles/app/tasks/shared_groups.yml'))
t=[x for x in d if 'Re-group' in x['name']][0]
print(t['ansible.builtin.file']['recurse'], 'mode' not in t['ansible.builtin.file'])
"
```
Expected: `True True`.

On-box pre-flight after the play runs (needs `-K` and `--ask-vault-pass`; run by hand, not
part of this plan's automated verify):
```bash
ssh 192.168.1.115 "sudo find /var/lib/mcp-wiki ! -group wikidata | head"
```
Expected: no output. Anything listed means the re-group did not take and the wiki adapter
will return nothing.

---

### 13. Rewrite `/resume` to use `search_all`

**Files**
- `/home/rahul/.claude/skills/resume/SKILL.md` — frontmatter + steps 2 and 3

**Do**
Depends on step 8. The tool without its consumer is half the change.

- `allowed-tools`: remove `mcp__erp-local__list_tasks`, `mcp__erp-local__list_notes`,
  `mcp__brief-local__list_briefs`, `mcp__wiki-local__search`; add
  `mcp__erp-local__search_all`. Keep every `get_*` entry — step 5 still reads items in
  full, now driven by each row's `ref`.
- Step 2 becomes a single `search_all(query, limit=15)` call. Delete the four-bullet store
  list and the "batched in a single message" instruction; delete the `wiki-local` failure
  caveat, since the wiki is no longer a separate connection (the server raises
  `SearchError` instead).
- Step 3 becomes "collapse rows sharing a `thread`" — ranking is server-side now, so drop
  the "rank by closeness then recency" sentence.
- Step 1 keeps its synonym instruction, with a pointer to erp task **#167**: fuzzy matching
  covers typos and word order, not synonyms.
- Step 5 reads the item named by the row's `ref`.
- Update the `description` frontmatter: one call, not a four-store sweep.

**Verify**
```bash
grep -c "list_tasks\|list_notes\|list_briefs\|wiki-local__search" /home/rahul/.claude/skills/resume/SKILL.md
grep -c "search_all" /home/rahul/.claude/skills/resume/SKILL.md
```
Expected: `0`, then a count ≥ 2.

---

### 14. Record the invariant-3 exemption in erp's CLAUDE.md

**Files**
- `/storage1/Documents/code/erp/CLAUDE.md` — Invariants section, and the `services/` line in
  the Layout block

**Do**
Under invariant 3 ("Domains are isolated"), add the exemption so a future reader does not
file it as a bug:

> **One exemption: `services/search.py`.** It is a read-only projection domain — it owns no
> schema and no DB file, imports no other `services/` module, and only ever reads. It spans
> tasker rows, the bridge brief store and the wiki tree to back the `search_all` MCP tool
> (spec 003). `tests/test_search.py` asserts the no-imports half.

**Verify**
```bash
grep -n "search.py" /storage1/Documents/code/erp/CLAUDE.md
```
Expected: at least one line, inside the Invariants section.
