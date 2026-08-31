# Skills

## Authoring standard

Every `SKILL.md` (and `agents/*.md`) follows this shape. Read it when adding or
redefining a skill; the always-on pipeline rules live in
`.specify/memory/constitution.md`, not here.

### Frontmatter

| Field | Rule |
|---|---|
| `name` | kebab-case, matches the directory |
| `description` | ≤ 2 sentences, then one `Trigger on:` line of comma-separated phrases. This loads into context every session — keep it tight. |
| `argument-hint` | present if the skill takes an argument |
| `allowed-tools` / `tools` | the minimum set the skill needs |
| `model` | pin only when the skill needs a specific one |
| `disable-model-invocation` | `true` for skills that must be called explicitly |

### Body

Fixed section order: **When to use → Procedure → Constraints → Done criteria**
(a skill may name the last two "What not to do" / "Done Criteria"). Core pipeline
skills open Procedure with *"Read `.specify/memory/constitution.md`."*

- Keep small templates inline in the skill; reference the shared scaffolds in
  `.specify/templates/` by path rather than copying them.
- Do not restate the constitution's pipeline map or status vocabularies — link to it.
- ~120 lines is a size smell, not a hard limit. Over it, look for what to cut or split.

### Overlap check

Two skills overlap when a normalized diff of their **Procedure + Constraints** sections
shares more than ~40% of instruction lines, **or** they take the same input artifact and
produce the same output artifact. An overlap is a consolidation signal: merge the two,
or lift the shared discipline into `.specify/memory/constitution.md` and have both
reference it. `/prune` (registry sweep) and `/forge` (Skeptic pass) both apply this.

## Registry

`kind`: **core** (portable pipeline, identical on every machine) · **overlay**
(this setup's domain — devkit / erp / brief) · **utility** (general, off the linear
pipeline). `last-reviewed` is bumped by `/prune` on a confirm-keep.

| name | kind | purpose | pipeline position / tag | last-reviewed |
|---|---|---|---|---|
| crawl | core | write `CODEBASE.md` context doc | orient | 2026-08-28 |
| designit | core | drill an idea into a locked spec | design | 2026-08-28 |
| plan-doc | core | write a numbered implementation plan | plan | 2026-08-28 |
| implement | core | execute a plan step by step | build | 2026-08-28 |
| code-review | core | review a diff/plan, bucket findings | review | 2026-08-28 |
| resolve-review | core | fix review findings in priority order | fix | 2026-08-28 |
| finalize | core | done-checks, changelog, version, commit | land | 2026-08-28 |
| diagnose | core | evidence-based debugging discipline | utility (stance) | 2026-08-28 |
| improve | core | four-check architecture scan, propose only | utility (off-pipeline) | 2026-08-28 |
| prototype | core | throwaway script to answer one question | utility (mid-build) | 2026-08-28 |
| grill | core | stress-test the user's reasoning | utility (pre-design) | 2026-08-28 |
| notice | core | log recurring skill friction | continuous | 2026-08-28 |
| land-feature | overlay | devkit ledger + invariant reconcile over `finalize` | overlay | 2026-08-28 |
| devkit-api-change | overlay | trace consumers before a devkit signature change | overlay | 2026-08-28 |
| query-db | overlay | inspect the `~/databases` SQLite stores | overlay | 2026-08-28 |
| handoff | overlay | compact a session into a brief-mcp handoff | overlay | 2026-08-28 |
| resume | overlay | sweep briefs/tasks/notes/wiki, pick a thread or start fresh | overlay | 2026-08-29 |
| postmortem | utility | write an incident postmortem | utility | 2026-08-28 |
| prototype-ui | utility | throwaway UI variants for a look-and-feel call | utility | 2026-08-28 |
| prune | utility | condense docs + sweep the skill registry | utility | 2026-08-28 |
| forge | utility | adversarial idea→skill assessor (fold / add / drop + rating) | utility | 2026-08-29 |
| bug-echo | utility | after a fix, hunt structural twins of the bug, ranked | utility (post-fix) | 2026-08-29 |
| distill | utility | compress material to what a skim misses + 3-4 lead points | utility | 2026-08-29 |
| observer | utility | audit the setup *as used* — transcript-derived fire counts, session shape, round-trip waste | utility (periodic) | 2026-08-30 |
| teachme | utility | closing concept-retro for a session | utility | 2026-08-28 |
| tldr | utility | add a glance-readable TLDR to a markdown file | utility | 2026-08-28 |
| yt-notes | utility | structured notes from a YouTube video | utility | 2026-08-28 |
| yt-tldr | utility | quick TL;DR from a YouTube video | utility | 2026-08-28 |
| consumer-impact (agent) | overlay | blast-radius trace of a devkit change | overlay | 2026-08-28 |
| ledger (agent) | overlay | write the devkit COMPLETE_ACTIONS entry | overlay | 2026-08-28 |
| verifier (agent) | overlay | run devkit tests + probe services | overlay | 2026-08-28 |
| skeptic (agent) | utility | adversarial reviewer, wraps `grill` | utility | 2026-08-28 |
