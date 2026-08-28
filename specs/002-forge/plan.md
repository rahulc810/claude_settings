status: authored
updated: 2026-08-29

# Plan 002 — forge

## Context

`notice`'s "Reviewing" step says to decide by hand whether a logged friction should
become a skill. That decision is where skill bloat and skill gaps both come from, and it
gets skipped. The pipeline has no step that takes a raw idea and adversarially decides
fold / add / drop. Plan 001 added a >40%-overlap consolidation flag to `/prune` for the
*live* set; there is no equivalent for *candidate* ideas, and the two would duplicate the
heuristic.

Designed via `/designit` this session (L1 + L2). Forced constraints: "no skill invokes
another" (so the adversarial pair is internal, not spawned) and the ≤60-line constitution
budget (so the shared overlap heuristic goes in `skills/README.md`, not the constitution).

## Decisions

1. **Internal two-pass adversary**, not spawned subagents — Proposer writes its full case
   to the report, then Skeptic (assume-it-should-not-exist posture) attacks, then
   Synthesis cites both. Respects the constitution's hard rule 1; one context, cheaper.
2. **New input dir `docs/skill-ideas/`**, freeform, one idea per `*.md`. `docs/notice.md`
   stays the one-line friction log; promoting a note is a manual copy. `notice`'s
   Reviewing paragraph is updated to hand off here.
3. **Report + draft-on-confirm.** `add` → write `skills/<name>/SKILL.md` + registry row;
   `fold` → apply via Edit, show the diff; `drop` → move idea to `_processed/` with the
   reason. Every processed idea moves to `_processed/`, verdict appended — never deleted.
4. **Overlap heuristic lives once**, in `skills/README.md` as an "Overlap check"
   subsection. `/prune` Step 5 and `forge`'s Skeptic pass both reference it.
5. **Explicit verdict rule**, not vibes: Distinctness ≤ 2 → fold (unless Recurrence ≥ 4
   and folding busts ~120 lines → add); Skill-fit ≤ 2 or Recurrence ≤ 2 → drop; else add.
   Rating is 5 axes 1–5, scored independent of the verdict.
6. **External-dir mode**: arg pointing outside `docs/skill-ideas/` → report-only, no
   archive, no writes into that tree. Input may be full `SKILL.md` drafts (model from the
   draft, don't invent).
7. **`forge` is a utility skill** (maintains the skill set, off the pipeline), explicit
   invocation only (`disable-model-invocation: true`), `model: claude-opus-5`.

## Out of Scope

- Migrating plan 001 from `docs/plans/` into `specs/` — 002 onward live in `specs/`, 001
  stays put with a cross-note.
- Auto-running `forge` on a schedule, or wiring it into `/prune`.
- Spawned-subagent adversary — revisit only if the internal pass proves to pull punches.
- Backfilling `docs/skill-ideas/` with existing `docs/notice.md` lines.

## Steps

### 1. Scaffold `docs/skill-ideas/`

**Files**
- `docs/skill-ideas/README.md` — new

**Do**
Create the dir with a `README.md`: one idea per `*.md` file, freeform (a paragraph, a
draft procedure, a pasted `SKILL.md` — anything). `_assessments/` and `_processed/` are
`forge`'s output — don't hand-edit. The scan glob is `docs/skill-ideas/*.md`
(non-recursive), so the underscore dirs are skipped.

**Verify**
```bash
test -f docs/skill-ideas/README.md && echo ok
```
Expected: `ok`.

### 2. Add the shared "Overlap check" to `skills/README.md`

**Files**
- `skills/README.md` — add a subsection under the authoring standard
- `skills/prune/SKILL.md` — point the overlap bullet at it

**Do**
In `skills/README.md`, after the body rules, add:

> ### Overlap check
> Two skills overlap when a normalized diff of their Procedure + Constraints sections
> shares >40% of instruction lines, **or** they have the same input artifact and produce
> the same output artifact. An overlap is a consolidation signal: merge the two, or lift
> the shared discipline into `.specify/memory/constitution.md`.

In `skills/prune/SKILL.md` Step 5, replace the inline ">40% … normalized diff …" bullet
text with: *"overlapping another `core` skill per the Overlap check in `skills/README.md`
— flag the pair for consolidation."*

**Verify**
```bash
grep -q '### Overlap check' skills/README.md && grep -q 'Overlap check in `skills/README.md`' skills/prune/SKILL.md && echo ok
```
Expected: `ok`.

### 3. Write `skills/forge/SKILL.md`

**Files**
- `skills/forge/SKILL.md` — new

**Do**
Frontmatter: `name: forge`; `description` ≤ 2 sentences + `Trigger on:- forge, assess
skill ideas, review skill-ideas, should this be a skill, model a skill from an idea`;
`argument-hint: "dir to scan (default docs/skill-ideas/)"`; `allowed-tools: Read, Grep,
Glob, Write, Edit, Bash`; `disable-model-invocation: true`; `model: claude-opus-5`.

Body (When to use → Procedure → Constraints → Done criteria):
- **Procedure**: (1) read `.specify/memory/constitution.md` + `skills/README.md`;
  (2) resolve scan dir, glob `*.md`, for each in order: (3) **Proposer pass** — model
  and steelman the skill (name, purpose, triggers, procedure, artifact/outcome, the
  recurring need), write it to the report; (4) **Skeptic pass** — attack on overlap (via
  the Overlap check), realness (evidence from `docs/notice.md`, `git log`), skill-shaped
  (procedure vs fact/preference), context cost; write to the report; (5) **Synthesis** —
  apply the verdict rule from Decision 5, citing named Proposer and Skeptic points;
  (6) **Rating** — the 5 axes (Recurrence, Distinctness, Skill-fit, Scope tightness,
  Context cost), 1–5 each with a one-line justification; (7) write
  `docs/skill-ideas/_assessments/<date>.md`; (8) local mode only — per-item confirm:
  `add` → `skills/<name>/SKILL.md` + registry row; `fold` → Edit + show diff; `drop` →
  move to `_processed/` with reason. Move every processed idea to `_processed/`, verdict
  appended.
- **Constraints**: Proposer's full case is written before the Skeptic pass starts;
  Skeptic assumes the skill should not exist and must be argued in; Synthesis must
  address any named overlap, not wave it past; external-dir mode is report-only (no
  archive, no writes outside this repo); never delete an idea file.
- **Done criteria**: every `*.md` in scope has a verdict + rating in the report;
  confirmed `add`/`fold` applied; processed ideas moved.

**Verify**
```bash
for k in 'Proposer' 'Skeptic' 'Synthesis' 'Overlap check' '_assessments' '_processed'; do
  grep -q "$k" skills/forge/SKILL.md || echo "MISSING: $k"
done; echo done
```
Expected: `done` with no MISSING lines.

### 4. Register `forge`

**Files**
- `skills/README.md` — registry table

**Do**
Add a row: `| forge | utility | adversarial idea→skill assessor (fold / add / drop +
rating) | utility | 2026-08-29 |`.

**Verify**
```bash
grep -q '^| forge |' skills/README.md && echo ok
```
Expected: `ok`.

### 5. Hand off from `notice`

**Files**
- `skills/notice/SKILL.md` — the "Reviewing" section

**Do**
In the Reviewing paragraph, replace the "worth a skill change → make it directly, or run
`/designit`" clause with: *"beyond a one-line tweak → copy the note into
`docs/skill-ideas/` and run `/forge`, which decides fold / add / drop."* Keep the
"one-off or covered → delete the line" behaviour.

**Verify**
```bash
grep -q 'docs/skill-ideas/' skills/notice/SKILL.md && echo ok
```
Expected: `ok`.

### 6. Add `forge` to the workflow map

**Files**
- `docs/skill-workflow.md`

**Do**
Add `forge` to the **Utility** list (`… · prune … · forge (idea→skill assessor) · …`).
In "When each fires", add: *"**`forge`** — explicit, when `docs/skill-ideas/` has
accumulated, or pointed at an external skill set to assess it."*

**Verify**
```bash
grep -q 'forge' docs/skill-workflow.md && echo ok
```
Expected: `ok`.

### 7. Index the plan

**Files**
- `specs/README.md` — already holds the 002 row (created with this plan)
- `docs/plans/README.md` — cross-note

**Do**
In `docs/plans/README.md`, add a line under the table: *"Plans 002+ live in
`specs/NNN-<slug>/plan.md`, indexed in `specs/README.md`."*

**Verify**
```bash
grep -q 'specs/' docs/plans/README.md && grep -q '^| 002 ' specs/README.md && echo ok
```
Expected: `ok`.
