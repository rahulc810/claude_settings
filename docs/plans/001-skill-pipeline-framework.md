# Plan 001 — Skill-Pipeline Framework

**Status:** authored
**Date:** 2026-08-28
**Design:** finalized via `/designit`, this session

## Context

Two skill sets exist in this repo: the mature one in `skills/` (~22 skills + 4 agents,
MCP-coupled, heavy CLAUDE.md "five stores" model) and a leaner rebuild in
`new_skill_variant/` (10 skills, uniform frontmatter, zero external coupling, adds
`crawl` + `finalize`). The lean set is the better base. Goal: one framework doc that
governs both the user's setup and a partner's pipeline — a shared core plus per-person
overlays — keeping skills sharp, light, maintainable.

The community has converged on spec-driven development: GitHub Spec Kit (v1.0.1, MIT) and
OpenSpec commit markdown artifacts next to code (`spec.md` → `plan.md` → `tasks.md`)
under `.specify/`, with `.specify/memory/constitution.md` re-injected on every phase.
Not converged: human-gate/async handoff, file↔store bridging, multi-agent handoff state.

Constraint forcing the design: skills load their `description` frontmatter into context
at session start, and the constitution loads on every skill run — base context cost is
the binding limit, so shared rules must be tiny and per-skill self-containment must not
mean duplicated boilerplate.

## Decisions

1. **Adopt GitHub Spec Kit's `.specify/` layout as the spine.** Don't invent structure
   for the solved part. `designit` and `plan-doc` outputs move into `specs/NNN-<slug>/`
   as `spec.md` and `plan.md`. Reason: formality, community alignment, less to maintain.
2. **`constitution.md` hard-capped at ≤ 60 lines**, the only file injected on every skill
   run. Everything not needed every run (frontmatter schema, size rules, lifecycle) goes
   in `skills/README.md`, read only when authoring. Reason: base context load is the
   binding constraint.
3. **Files are canonical; stores are a mirror-only projection** — except
   `specs/*/gates/*`, a narrow read-write channel. Pull every MCP server and the pipeline
   still runs. Reason: harness must work with or without stores, and local/remote must
   not disagree on state.
4. **One explicit handshake field, generalized**: every pipeline artifact carries a
   2-line header `status:` + `updated:`. Downstream skill advances only when upstream
   `status:` says ready. No ledger, no envelope beyond those two lines. Reason: `status:`
   is the only load-bearing metadata; the rest is derivable and would rot.
5. **Human gates are park-and-resume.** A skill needing input writes
   `specs/NNN-<slug>/gates/NNN-<gate>.md` (`status: awaiting-input`) and stops — no held
   process. Interactive skills (designit, plan-doc, grill) answer in-session;
   long-running skills (implement, resolve-review) park and resume via `/resume` or
   re-invocation. Reason: pipeline already avoids long-lived waits; async falls out of
   on-disk state.
6. **Bridge adapter spec'd here, built in the orchestrator phase.** Outward: mirror
   `awaiting-input` gates + plan statuses to a store. Inward: write a store reply back as
   `response:` + `status: answered` into the gate file only. Reason: async human comms is
   the one unsolved piece; keep it thin and separately built.
7. **No skill invokes another.** Human drives every transition. Reason: keeps the
   sequence something the user knows, not a wrapper; the orchestrator (next phase) is the
   only thing allowed to auto-advance.
8. **Core set vs overlay.** Core (identical both setups): crawl, designit, plan-doc,
   implement, code-review, resolve-review, finalize, diagnose, improve, prototype, grill,
   notice. `land-feature` becomes a thin devkit overlay over `finalize`'s contract.
   Reason: partner's pipeline must not carry devkit/erp-specific skills.

## Steps

### 1. Scaffold `.specify/`

**Files**
- `.specify/memory/constitution.md` — new; always-injected rules file
- `.specify/templates/{spec,plan,review,gate}-template.md` — new; artifact scaffolds
- `.specify/README.md` — new; one paragraph on what `.specify/` is

**Do**
Create the tree. `constitution.md` contains exactly, in ≤ 60 lines:
- Pipeline map: `crawl→CODEBASE.md · designit→specs/NNN/spec.md · plan-doc→specs/NNN/plan.md · implement→code · code-review→specs/NNN/review.md · resolve-review→(review.md status) · finalize→commit`
- Status vocabularies, one line each: spec `draft→accepted→superseded`; plan
  `authored→implemented→superseded→abandoned`; review `open→worked-on→closed`; gate
  `awaiting-input→answered→consumed`
- Gate protocol: write `gates/NNN-<gate>.md`, set `status: awaiting-input`, stop; resume
  when `status: answered`, then set `consumed`
- Three hard rules: (a) no skill invokes another; (b) files canonical, stores mirror-only
  except `gates/`; (c) an artifact present at its path with `status: <ready-state>` is
  the only "produced" signal

**Verify**
```bash
test -f .specify/memory/constitution.md && wc -l < .specify/memory/constitution.md
```
Expected: file exists, line count ≤ 60.

### 2. Write the four templates

**Files**
- `.specify/templates/spec-template.md`, `plan-template.md`, `review-template.md`, `gate-template.md`

**Do**
Each opens with the 2-line header block:
```
status: <initial>
updated: YYYY-MM-DD
```
- `spec-template.md` — sections: Problem · Goals · Non-Goals · Considered Approaches ·
  Decision (chosen + reason) · Design · Open Questions (from `new_skill_variant/designit`)
- `plan-template.md` — sections: Context · Decisions · Out of Scope · Steps (each: Files /
  Do / Verify with expected output) (from `new_skill_variant/plan-doc`)
- `review-template.md` — sections: Scope · Findings bucketed Blocking / Should-fix / Nit,
  each with file:line, what's wrong, why, suggested fix. Header `status: open`
- `gate-template.md` — header + fields: `skill:`, `asked:`, `question:`, `options:`,
  `response:` (empty)

**Verify**
```bash
for f in spec plan review gate; do grep -q '^status:' .specify/templates/$f-template.md || echo "MISSING header: $f"; done
```
Expected: no output.

### 3. Write `skills/README.md` — authoring standard + registry

**Files**
- `skills/README.md` — new

**Do**
Two parts.
*Authoring standard*: frontmatter fields (`name`; `description` ≤ 2 sentences + one
`Trigger on:` line; `argument-hint`; `tools`; `model`; `disable-model-invocation`); body
section order (When-to-use → Procedure → Constraints → Done-criteria); small templates
inline, shared scaffolds referenced from `.specify/templates/`; ~120-line size smell.
*Registry table*: one row per skill and agent — `name | purpose | map-position or
overlay/utility | last-reviewed (YYYY-MM-DD)`. Populate from current `skills/` and
`agents/` contents, tagging each core / overlay / utility per Decision 8.

**Verify**
```bash
grep -c '^| ' skills/README.md; ls skills/ | wc -l
```
Expected: registry row count ≥ skill-directory count.

### 4. Migrate core skills to the contract

**Files**
- `skills/{crawl,designit,plan-doc,implement,code-review,resolve-review,finalize,diagnose,improve,prototype,grill,notice}/SKILL.md`
  (port `crawl` and `finalize` in from `new_skill_variant/`)

**Do**
For each core skill:
- Procedure step 1 becomes: "Read `.specify/memory/constitution.md`."
- Output path updated: designit → `specs/NNN-<slug>/spec.md`; plan-doc →
  `specs/NNN-<slug>/plan.md`; code-review → `specs/NNN-<slug>/review.md`
- Any skill with a human decision point writes a gate file per the protocol instead of
  only prompting inline
- Remove inline copies of status vocab / pipeline map; reference the constitution
- Frontmatter conformed to the standard from Step 3

**Verify**
```bash
for d in crawl designit plan-doc implement code-review resolve-review finalize diagnose improve prototype grill notice; do
  grep -q 'constitution.md' skills/$d/SKILL.md || echo "no constitution ref: $d"
done
```
Expected: no output.

### 5. Split `land-feature` into core `finalize` + devkit overlay

**Files**
- `skills/finalize/SKILL.md` — core, generic (changelog / semver / conventional commit / done-checks)
- `skills/land-feature/SKILL.md` — reduced to devkit overlay: reads repo `CLAUDE.md`,
  does `COMPLETE_ACTIONS.md` + invariant reconciliation, defers commit mechanics to
  `finalize`'s contract

**Do**
Move every devkit-specific instruction (invariant table, `COMPLETE_ACTIONS.md` format,
consumer smoke tests) out of any core skill into `land-feature`. `finalize` must contain
zero repo-specific names. Tag `land-feature` `overlay` in the registry.

**Verify**
```bash
grep -iE 'devkit|COMPLETE_ACTIONS|erp' skills/finalize/SKILL.md
```
Expected: no output.

### 6. Establish core / overlay separation

**Files**
- `skills/README.md` registry (tags)
- `docs/skill-workflow.md`

**Do**
No directory move — separation is by registry tag plus a `## Core` / `## Overlay` /
`## Utility` grouping in `docs/skill-workflow.md`. State that the core set is the
portable unit: copying `.specify/` + the 12 core `skills/` dirs + `skills/README.md`'s
standard section to another machine yields a working pipeline with no edits.

**Verify**
```bash
grep -E '^## (Core|Overlay|Utility)' docs/skill-workflow.md | wc -l
```
Expected: `3`.

### 7. Specify the bridge adapter (contract only)

**Files**
- `.specify/bridge.md` — new; spec, not code

**Do**
Document: (a) outward watch on `specs/*/gates/*` with `status: awaiting-input` and on
plan `status:` lines → push to a store (erp task or brief thread), payload = gate/plan
path + question + options; (b) inward: a store reply resolves to exactly one gate file,
written back as `response: <verbatim>` + `status: answered`, nothing else touched;
(c) idempotency: re-running the adapter over an already-`answered` gate is a no-op;
(d) absent adapter, gates are answered at the terminal and the pipeline is unaffected.
Mark build as orchestrator-phase scope.

**Verify**
```bash
grep -qE 'outward|inward|idempotent' .specify/bridge.md && echo ok
```
Expected: `ok`.

### 8. Extend `/prune` to skills and agents

**Files**
- `skills/prune/SKILL.md`

**Do**
Add a step: read `skills/README.md` registry; flag any skill/agent that is (a) not
referenced in `docs/skill-workflow.md`'s map nor tagged `overlay`/`utility`,
(b) `last-reviewed` older than 90 days, or (c) over the 120-line smell. Present flags,
human confirms before any deletion. Registry `last-reviewed` bumped on confirm-keep.

**Verify**
```bash
grep -q 'registry' skills/prune/SKILL.md && grep -q 'last-reviewed' skills/prune/SKILL.md && echo ok
```
Expected: `ok`.

### 9. Reconcile `docs/skill-workflow.md`

**Files**
- `docs/skill-workflow.md`

**Do**
Rewrite the map to the `.specify/` artifact paths and the core/overlay/utility grouping.
State the two invariants: no skill calls another; the human (or, later, the orchestrator)
drives every transition. Point to `.specify/memory/constitution.md` as the source of
truth for status vocab.

**Verify**
```bash
grep -q 'specs/NNN' docs/skill-workflow.md && grep -q 'constitution.md' docs/skill-workflow.md && echo ok
```
Expected: `ok`.

## Out of scope

- **The orchestrator / runner** — next phase. This doc defines its contracts (pipeline
  map, gate statuses, bridge plug-in) but builds no auto-advance.
- **Building the bridge adapter** — Step 7 is its spec only.
- **Rewriting non-core skills** (`postmortem`, `teachme`, `tldr`, `yt-*`, `query-db`,
  `devkit-api-change`) — registry row now, conformance pass later.
- **The five-store MCP model** — unchanged; remains the cross-session/domain layer. Only
  its relationship to pipeline state is fixed (mirror-only).
- **`settings.json`, hooks, keybindings.**
- **Deploying to the partner's machine** — this produces the portable core; the copy
  step is theirs.
