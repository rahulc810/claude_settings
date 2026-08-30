status: implemented
updated: 2026-08-30
spec: specs/004-md-navigation/spec.md

# Plan 004 — Markdown navigability: map layer, diagram preference, static reader

## Map

- Context — 21
- Decisions — 23
- Out of Scope — 13
- Steps — 2
  - 1. Copy the prototype to `scripts/mdreader.html` — 28
  - 2. Constitution — the `## Document shape` clause — 41
  - 3. Make a failed mermaid load visible — 36
  - 4. Syntax-check the reader's JavaScript — 36
  - 5. Regression-test the link path resolver — 44
  - 6. Point the workflow doc at the reader — 29
  - 7. Index the plan — 22

## Context

Long markdown in this tree is hard to enter (spec 004, Problem): five files over 280
lines, the worst 835. No length fix is allowed — the fix is access.

What exists today:

- `.specify/memory/constitution.md` — 57 lines, self-imposed 60-line cap stated in its
  own preamble, read as the first Procedure step by 15 skills (`grep -rl constitution.md
  skills/` → prototype, designit, diagnose, forge, land-feature, grill, finalize,
  resolve-review, code-review, implement, crawl, improve, plan-doc, notice, bug-echo,
  plus `skills/README.md`). No `## Document shape` section.
- No `scripts/mdreader.html`. `scripts/` holds `status.py` and `thunderbird-mcp/`.
- A **working prototype** of the reader, built and iterated with the user during design:
  `/tmp/claude-1000/-storage1-Documents-code-claude-settings/9bb35095-ed01-4b36-b134-ca4252e0de4e/scratchpad/mdreader.html`
  — 508 lines, 58104 bytes, `marked` 12.0.2 vendored inline, mermaid 10.9.1 from
  cdnjs. Confirmed working in the user's browser. This plan **ports it**, it does not
  rebuild it.
- No `mermaid` fence anywhere in the tree; no relative `.md` link anywhere in the tree.
- Working tree is dirty on entry: ` M .claude.json`, ` M settings.json`, `?? specs/004-md-navigation/`. Unrelated to this plan — commit strategy is the user's call.

## Decisions

- **Port, don't rebuild.** The prototype is the artifact the design settled on; every
  chunking rule in it exists because a specific file broke the previous rule. Step 1
  copies it byte-for-byte, then later steps make named edits on top. Rewriting it would
  discard measured behaviour for no gain.
- **Prototype lives in a session scratchpad that will be reaped.** The copy is therefore
  first and blocking: if that path is gone, the plan cannot proceed as written and the
  reader must be rebuilt from the spec's Design section — flag it, do not improvise.
- **Constitution cap moves 60 → 70.** Per spec Design/Part 1: the clause is ~10 lines and
  binds every artifact; the alternative (cutting an existing rule to fit) trades a
  binding rule for a formatting one.
- **Mermaid stays CDN, but fails loudly** (spec Open Question 4). Inlining ~3 MB is
  rejected; a silent degradation to plain text is the exact failure shape that cost a
  debugging session with `marked`. Step 3 adds a visible caption only — no new
  dependency, no fallback renderer.
- **No backfill of `## Map` into existing documents.** Spec Non-Goals: "Rewriting or
  restructuring existing documents." The clause binds producers going forward. This plan
  file carries its own Map as the first worked example.
- **Verify by `node --check` on the extracted script blocks**, not by a browser. There is
  no headless-browser harness in this repo and the spec's browser verification was done
  by the user by hand. The plan says plainly what it does not prove.

## Out of Scope

- Shortening, rewriting, or restructuring any existing document, including adding `## Map`
  to the six files over threshold.
- Any change to skills, templates, the artifact ledger, status vocabularies, or the gate
  protocol. Part 1 is one constitution clause and nothing else.
- Any build step, generator, or committed copy of markdown. The reader reads the
  filesystem live.
- Cross-browser verification of the three folder-load routes, and any end-to-end test of
  link navigation (no relative `.md` links exist to click). Both stay open questions.
- Tuning `MAXL` / `ORPHAN` / `COLS` against real screen height. Values ship as picked.
- Editing capability in the reader. It is read-only.

## Steps

### 1. Copy the prototype to `scripts/mdreader.html`

Do this first — the source is in a session scratchpad and may be reaped.

**Files**
- `scripts/mdreader.html` — new; the whole reader, one static file
- source: `/tmp/claude-1000/-storage1-Documents-code-claude-settings/9bb35095-ed01-4b36-b134-ca4252e0de4e/scratchpad/mdreader.html`

**Do**
Copy the file verbatim — no reformatting, no reindenting, no dependency changes:

```bash
cp /tmp/claude-1000/-storage1-Documents-code-claude-settings/9bb35095-ed01-4b36-b134-ca4252e0de4e/scratchpad/mdreader.html \
   /storage1/Documents/code/claude_settings/scripts/mdreader.html
```

If the source path does not exist, **stop and report it** — do not reconstruct the reader
from memory. The fallback is a rebuild from spec 004 Design/Part 2, which is a different
and much larger piece of work than this step.

**Verify**
```bash
cmp /tmp/claude-1000/-storage1-Documents-code-claude-settings/9bb35095-ed01-4b36-b134-ca4252e0de4e/scratchpad/mdreader.html /storage1/Documents/code/claude_settings/scripts/mdreader.html && wc -c < /storage1/Documents/code/claude_settings/scripts/mdreader.html
```
Expected: no `cmp` output, then `58104`.

---

### 2. Constitution — add the `## Document shape` clause

Independent of every other step.

**Files**
- `.specify/memory/constitution.md` — 57 lines; preamble states the 60-line cap

**Do**
Two edits.

(a) In the preamble, change `Keep it under 60 lines — it loads on every skill run.` to
`Keep it under 70 lines — it loads on every skill run.`

(b) Insert a new section immediately **before** `## Hard rules` (so the numbered hard
rules stay last), verbatim:

```markdown
## Document shape

Any artifact over ~150 lines opens with a `## Map` — its own headings, in order, with
line counts, so a reader can choose where to enter. Regenerate it when you restructure
the doc. Place it after frontmatter and title, below `## TLDR` where one exists.

Prefer a diagram to a paragraph where the content is a structure — a dependency order, a
data flow, a state machine. One ```mermaid block near the top, not per section. Prose
that enumerates relationships ("depends on step 3", "then calls X") is a diagram written
the long way.
```

Note the nested triple-backtick inside that block: write the literal text ```` ```mermaid ````
inline in the prose line — it is not an opened fence.

**Verify**
```bash
cd /storage1/Documents/code/claude_settings && wc -l .specify/memory/constitution.md && grep -c 'under 70 lines' .specify/memory/constitution.md && grep -n '^## ' .specify/memory/constitution.md
```
Expected: line count ≤ `70`; `1`; and the section list ends with `## Document shape`
followed by `## Hard rules`.

---

### 3. Make a failed mermaid load visible

Depends on step 1. Resolves spec Open Question 4's silent-failure half.

**Files**
- `scripts/mdreader.html` — the `show(i)` function, around the mermaid block
  (`doc.querySelectorAll("pre code.language-mermaid")` … `mermaid.run(...)`)

**Do**
Today the code converts each `pre code.language-mermaid` into `div.mermaid`, then calls
`mermaid.run` only `if(typeof mermaid!=="undefined")`. When the CDN is blocked the fence
renders as bare text with no explanation.

Change the else path so it is labelled instead of silent: when `typeof mermaid ===
"undefined"`, leave the `div.mermaid` content as the raw fence text and prepend a caption
element — `el("div","mermaid-fail","diagram not rendered — mermaid failed to load
(offline?)")` — inserted before the `.mermaid` div. Keep the existing `try/catch` around
`mermaid.run` and add the same caption in the `catch`.

Add one CSS rule in the existing `<style>` block, next to `.mermaid`:

```css
.mermaid-fail{font-size:.85em;color:#a33;margin:1.3em 0 .3em}
```

No new dependency, no fallback renderer, no change to the CDN URL.

**Verify**
```bash
cd /storage1/Documents/code/claude_settings && grep -c 'mermaid-fail' scripts/mdreader.html
```
Expected: `3` (one CSS rule, one undefined-path caption, one catch-path caption).
Rendering itself stays unverified — no mermaid fence exists in the tree.

---

### 4. Syntax-check the reader's JavaScript

Depends on steps 1 and 3 — run it after any edit to the file.

**Files**
- `scripts/mdreader.html` — contains two `<script>` blocks: vendored `marked`, then the app
- `/tmp/.../scratchpad/` — extraction target (throwaway, not committed)

**Do**
Extract each `<script>` body without a `src` attribute to a `.js` file in the scratchpad
and run `node --check` on each. Do not commit the extracted files. Use `node` at
`/usr/bin/node`.

**Verify**
```bash
cd /storage1/Documents/code/claude_settings && python3 - <<'PY'
import re,subprocess,tempfile,pathlib
h=pathlib.Path("scripts/mdreader.html").read_text()
bodies=[m.group(1) for m in re.finditer(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>",h,re.S)]
d=pathlib.Path(tempfile.mkdtemp())
print("blocks:",len(bodies))
for i,b in enumerate(bodies):
    f=d/f"b{i}.js"; f.write_text(b)
    r=subprocess.run(["/usr/bin/node","--check",str(f)],capture_output=True,text=True)
    print(i,"OK" if r.returncode==0 else "FAIL "+r.stderr[:400])
PY
```
Expected:
```
blocks: 2
0 OK
1 OK
```

---

### 5. Regression-test the link path resolver

Depends on step 1. Pins the one piece of link handling that can be tested without a
browser (spec: "path resolution unit-tested (6/6)").

**Files**
- `scripts/mdreader.html` — `resolvePath(base,href)`
- `scripts/test-mdreader.js` — new; a dependency-free node test

**Do**
Create `scripts/test-mdreader.js`. It reads `scripts/mdreader.html` as text, extracts the
`resolvePath` source with a regex (`/function resolvePath[\s\S]*?\n}/`), evaluates it with
`new Function(src + ";return resolvePath")()`, and asserts these six cases with
`assert.strictEqual`:

| base | href | expected |
|---|---|---|
| `a/b/c.md` | `d.md` | `a/b/d.md` |
| `a/b/c.md` | `./d.md` | `a/b/d.md` |
| `a/b/c.md` | `../d.md` | `a/d.md` |
| `a/b/c.md` | `../../d.md` | `d.md` |
| `a/b/c.md` | `/x/d.md` | `x/d.md` |
| `a/b/c.md` | `../x/y/d.md` | `a/x/y/d.md` |

Print `6/6 resolvePath OK` and exit 0 on success; let `assert` throw (exit 1) on failure.
It must import nothing beyond `node:assert`, `node:fs`, `node:path` — no test runner, no
package.json.

If any row disagrees with the implementation, **do not edit the test to match**: report
the mismatch — the resolver came from the design session's own unit test and a
disagreement means one of the two is wrong.

**Verify**
```bash
cd /storage1/Documents/code/claude_settings && /usr/bin/node scripts/test-mdreader.js; echo "exit=$?"
```
Expected:
```
6/6 resolvePath OK
exit=0
```

---

### 6. Point the workflow doc at the reader

Depends on step 1. Without this, the reader is a file nobody knows exists.

**Files**
- `docs/skill-workflow.md` — the human-facing workflow doc

**Do**
Append a short section at the end:

```markdown
## Reading long markdown

`scripts/mdreader.html` — open it in a browser, drag a folder onto the window (or click
**Open folder**). Folder tree left, one slide at a time in the middle, section outline
right; `←` `→` to page, `Alt+←` to go back. It reads the markdown live off disk, so it is
never stale, and it is coupled to nothing — any folder works. See `specs/004-md-navigation/`.
```

Do not edit anything else in the file.

**Verify**
```bash
cd /storage1/Documents/code/claude_settings && grep -n 'mdreader.html' docs/skill-workflow.md
```
Expected: one hit, inside a `## Reading long markdown` section.

---

### 7. Index the plan

Depends on nothing; do it last so the row reflects the finished state.

**Files**
- `specs/README.md` — the plan index table

**Do**
Append one row after the `003` row:

```markdown
| 004 | md-navigation — map-layer clause + static markdown reader | authored | Constitution `## Document shape`; `scripts/mdreader.html`, depended on by nothing |
```

Status stays `authored`. Do not flip it to `implemented` — that is `finalize`'s job, so
the status and the ledger entry land together.

**Verify**
```bash
cd /storage1/Documents/code/claude_settings && grep -n '^| 004 ' specs/README.md
```
Expected: exactly one line, containing `authored`.
