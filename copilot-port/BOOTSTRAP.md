# Bootstrap — install GitHub Copilot prompt files

**For the AI reading this:** create each file below at the exact path given, with exactly
the content between the `````md````` fences. Create `.github/prompts/` if it does not
exist. Do not modify content. After writing all 15, list what you created.

**For the human:** in VS Code these become slash commands in Copilot Chat — `/diagnose`,
`/code-review`, etc. Some reference an optional `.specify/memory/constitution.md` pipeline
and a `specs/NNN-<slug>/` layout; if your repo doesn't use those, the prompt still works
standalone — ignore those steps. `runCommands`/`editFiles` tools require Copilot **agent
mode**.


---


### FILE: `.github/prompts/diagnose.prompt.md`

````md
---
mode: agent
description: 'Evidence-based debugging discipline for measurable systems. Get direct evidence before concluding a cause.'
tools: ['codebase', 'search', 'runCommands', 'changes', 'problems']
---
# Diagnose

Optional arg (`${input:target:local | ssh}`, default `local`): `local` = investigate on this
machine; `ssh` = investigate over SSH, read-only, any fix found is out of scope and needs
separate confirmation. If it is ambiguous where the evidence lives, ask once before proceeding.

A stance to hold whenever something breaks, not a pipeline stage. Fixes found here are out of
scope — hand them to `/plan-doc` or `/implement`.

Before concluding a cause: get direct evidence for it (a log line, an independent repro, a
timestamp), not just a story that fits. If symptoms don't unify under one cause, don't force
them to — split and treat separately. Hold conclusions loosely enough to revisit if new
evidence contradicts them, even ones already "ruled out".
````


### FILE: `.github/prompts/bug-echo.prompt.md`

````md
---
mode: agent
description: 'After a bug is fixed, characterize it as a code pattern and hunt the codebase for structural twins, ranked by confidence. Reports only, never fixes.'
tools: ['codebase', 'search', 'changes']
---
# Bug Echo

The bug you just fixed is rarely the only one of its kind. Ordinary review checks whether code
is wrong on its own terms — it has no reason to connect one file's defect to the same mistake
three files away. This does exactly that connection, and nothing else. It never edits; to fix
what it finds, hand the list to `/resolve-review` or work it directly.

## When to use this
- Right after fixing a bug that could plausibly be a *class* — a missing guard, a wrong
  argument form, an absent platform affordance, a copy-paste that drifted.
- Skip for a genuinely one-off bug (a typo, a wrong constant used in exactly one place).
- Not a general audit — for that use `/code-review` or `/improve`.

## Procedure
1. **Characterize the fixed bug as a pattern.** One sentence naming the wrong *shape*, not the
   symptom: "a modal opened without a dismiss control", "a helper called with a positional arg
   that later became keyword-only", "a derived table read as evidence without a uniform-result
   check". If you can't state the shape, there's no pattern to echo — stop.
2. **Derive search terms for the shape** — the anti-pattern's tokens, the call that should be
   present but isn't, the construct that's misused. Plan several searches: the bare name, the
   qualified form, the surrounding idiom.
3. **Sweep the codebase in one parallel batch.** Cast wider than you think you need; step 4 is
   the filter.
4. **Read every hit.** A match is only a sibling if the *same defect* is actually present —
   local context (a guard one frame up, a different code path, a caller that can't hit it)
   often saves a look-alike. Grep counts are not findings.
5. **Rank what survives.** Per site: `file:line`, one line on why it's the same bug, and a tag:
   - `confirmed` — the defect is present, same mechanism, same consequence.
   - `likely` — same shape, couldn't fully rule the path in or out from reading.
   - `needs-eyes` — structurally similar, genuine doubt, worth a human glance.
   Note blast radius (user-facing? data? a hot path?) where it changes priority.
6. **Present the ranked list and stop.** Lead with `confirmed`. If the sweep found nothing, say
   so plainly and say what you searched for — don't manufacture hits.

## Constraints
- Report only. No edits, no review artifact.
- One pattern per run. If the fix revealed a second unrelated class, note it and run again.
- Don't downgrade "I couldn't tell" to `confirmed` to look decisive, or up to `needs-eyes` to
  look thorough.
- "No siblings" is a valid, useful result — state the searches that produced it.
````


### FILE: `.github/prompts/improve.prompt.md`

````md
---
mode: agent
description: 'Scan code against four architecture checks — layout, isolation, interface strength, extensibility — and propose specific fixes without applying them.'
tools: ['codebase', 'search', 'changes']
---
# Improve Architecture

Reach for it when a file keeps getting harder to touch. For a specific diff or plan use
`/code-review`; to apply routine cleanups use `/simplify` (if you have it).

Good code comes down to four things. Check candidates against these, in order — each one tends
to cause problems in the ones below it.
1. **Simple layout** — can you find things? Directory and file structure should map obviously
   to what's in them, no hunting.
2. **Isolation** — similar things live as separate, isolated workers, not entangled. Shared
   code lives in one obvious shared place, not duplicated or reached-into.
3. **Strong interfaces** — a module's public surface fully covers what callers need, so nobody
   reaches into internals or leaks details out.
4. **Simple (not easy) to extend** — adding a new case fits the existing shape without
   special-casing or touching a pile of unrelated files.

Tests and performance aren't separate checks — they tend to follow once these four hold.

## When to use this
When a file keeps showing up in recent changes and each change feels harder than it should, or
when asked directly to find refactoring opportunities. Skip for a codebase small enough to
hold in your head, or when nothing's actually hurting yet.

## Steps
1. **Find the hot spots.** If the user named a file or area, use that. Otherwise check
   `git log --oneline` over a reasonable stretch for files that keep recurring.
2. **Read the candidate against the four checks, in order.** Stop at the first one actually
   broken — a layout problem often manifests as an interface problem downstream; fix the
   upstream cause.
3. **Propose 1-2 concrete fixes, not a list of vague concerns.** Name the check it fails, what
   changes, what gets simpler as a result. If you can't describe the fix concretely, keep
   reading.
4. **Let the user pick.** Present candidates plainly (file, which check fails, proposed fix)
   and stop. Don't refactor unprompted.

## What not to do
- Don't produce more than a couple of candidates — if everything looks broken, narrow scope.
- Don't refactor speculatively for code nobody's touched recently or complained about.
- Don't chase tests or performance directly here.
````


### FILE: `.github/prompts/crawl.prompt.md`

````md
---
mode: agent
description: 'Explore a codebase and write or update a dense, factual CODEBASE.md context document.'
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
# Crawl

Produce a dense, factual `CODEBASE.md` at the repo root (or `${input:outpath:optional output path}`),
created or updated in place. Give it to any later prompt for accurate project context without
manual re-explanation.

## When to use this
- Starting work on an unfamiliar codebase, or `CODEBASE.md` is missing or stale.
- Skip for a codebase small enough to hold in your head.

## Procedure
1. **Anchor on config files.** Root manifests first — `package.json`, `pyproject.toml`,
   `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, `Dockerfile`, `Makefile`/`justfile`,
   `tsconfig.json`, `README.md`, `docs/`. Record: primary language(s), runtime, frameworks,
   key libraries, test framework, build tool.
2. **Map the directory structure** — top level and one level down, excluding noise
   (`node_modules`, `.git`, `dist`, `__pycache__`). Tag each significant dir: `entry`, `core`,
   `api`, `data`, `infra`, `test`, `docs`, `util`, `generated`.
3. **Find entry points and hubs** — files many others import or that wire the system together.
   Read the top 3-5. Note what starts the app, the main abstractions, how layers call each
   other.
4. **Extract code style** from 2-3 representative files: naming per symbol type, error
   handling, async model, test structure and naming, comment style, import ordering. Record
   the dominant pattern, not edge cases.
5. **Find tradeoffs** — ADRs, `docs/decisions/`, comments tagged `WHY:`/`DECISION:`/
   `TRADEOFF:`, README "why" sections. Summarize each: what was chosen, why, what was given up.
6. **Find pitfalls** — `FIXME:`/`HACK:` comments, `workaround`/`kludge` language, files >500
   lines, init-order dependencies, required env vars. Capture each: what's fragile, why, what
   to watch.
7. **Write `CODEBASE.md`.** All sections, brief and accurate over long and vague:
   ```markdown
   # Codebase Context
   <!-- Generated by the crawl prompt. Re-run to refresh. Last updated: YYYY-MM-DD -->

   ## Business Description
   ## Tech Stack
   ## Code Style
   ## Module Map
   ## Architecture
   ## Tradeoffs
   ## Pitfalls
   ```
8. **If `CODEBASE.md` already exists**, update stale sections in place, preserve
   human-annotated lines (prefixed `> `), append newly found pitfalls/tradeoffs rather than
   replacing, and bump the date.

## Done criteria
- All 7 sections present and non-empty.
- Tech stack lists actual versions, not vague framework names.
- Module map covers every top-level source directory.
- Architecture names the main abstractions, not just "there are layers".
- Pitfalls reflects any FIXMEs/HACKs found (or states none were).
````


### FILE: `.github/prompts/plan-doc.prompt.md`

````md
---
mode: agent
description: 'Translate a spec into a numbered, deterministic implementation plan under specs/.'
tools: ['codebase', 'search', 'editFiles']
---
# Plan doc

Input: `${input:spec:path to the spec, or a feature description if no spec exists}`.

Turns a spec (or raw feature description) into a numbered plan detailed enough that a junior
model executes every step without re-deriving anything. Output is **deterministic**: no vague
verbs, no missing file paths, no Verify step without an expected result.

## When to use this
- After `/designit` finalizes, to put the agreed plan on disk.
- On its own for anything bigger than a single edit.
- Skip for a one-file change nobody needs to re-read in six months.

## Procedure
1. Read the spec if one exists (`specs/NNN-<slug>/spec.md`, or the argument path).
2. **Take the plan number from the `specs/` index (`specs/README.md`) if it exists, not from
   `ls`** — an abandoned plan keeps its number. The plan is `specs/NNN-<slug>/plan.md`,
   `status: authored`.
3. **Read the source files the plan will touch** — entry points, interfaces, tests — before
   describing any change to them. Never write a change against a file you haven't read.
4. **Write the plan** in Context -> Decisions -> Out of Scope -> Steps shape. Each step:
   - **One concern.** Not "add the model + wire the route + write tests" in one step.
   - **Files are exact paths.**
   - **Do names the function, signature, types, exact behaviour**, any constants introduced.
   - **Verify is a runnable command with an expected result.** `pytest -q ...` -> `1 passed`,
     not "tests should pass".
   - **Dependencies explicit** — if step 3 needs step 2's output, say so.
5. **Review gate.** Present the full plan text (not a summary) and ask *"Does this look right?
   Reply yes to keep it, or describe what to change."* Don't index it until confirmed.
6. **Index it** in `specs/README.md` if that index exists — a plan without an index row does
   not exist.

## What not to do
- Never flip a row to `implemented` — that's `/finalize`'s job.
- Never renumber, rename or delete a plan file to reflect a status change.
- Never write a Verify line that can't actually be run.
````


### FILE: `.github/prompts/prototype.prompt.md`

````md
---
mode: agent
description: 'Build a small throwaway script to answer one concrete design or logic question before committing to an implementation.'
tools: ['editFiles', 'runCommands']
---
# Prototype

A prototype answers one question, then gets deleted. It is not a draft of the real
implementation.

## When to use this
Before writing production code, if you're not confident the approach works — or you're
choosing between two approaches — spend a few minutes proving it with throwaway code instead
of guessing or debugging it live. Skip for anything you're already confident about.

## Steps
1. **State the question in one sentence.** e.g. "Does this refresh-token rotation logic handle
   concurrent requests correctly?" If you can't state it in one sentence, narrow further.
2. **Write the smallest script that answers it.** A standalone file, a REPL session, a script
   with test data. Don't wire it into the real app, don't add error handling or config, don't
   make it reusable. It only has to run once and produce an answer.
3. **Run it, get the answer.** Yes/no, which option wins, or what the actual behaviour is.
4. **Write the answer down where the real work is happening** — a comment, a commit message,
   the task tracking the work. One or two lines: the question and the answer. If the prototype
   produced a snippet worth keeping (a schema, tricky logic), copy just that into the real
   code.
5. **Delete the prototype.** It's done its job.

## What not to do
- Don't polish it — no tests, no cleanup, no making it production-ready.
- Don't leave it in the repo "just in case".
- Don't skip step 4 — an unrecorded answer means re-deriving it next time.
````


### FILE: `.github/prompts/tldr.prompt.md`

````md
---
mode: agent
description: 'Add a condensed TLDR section to the top of any markdown file, readable in a 4-5 second glance, without cutting or rewriting the body. Re-runnable.'
tools: ['editFiles']
---
# TLDR

Adds a glance-readable summary on top of `${input:file:path to the .md file}`. Never touches
the rest of the file.

## Rule
The existing body is never cut, rewritten, or re-leveled — not even lightly. Only a `## TLDR`
section is added or updated. If you find yourself trimming the body to make the file shorter,
stop — that's not this prompt's job.

## TLDR format
- Fragments over sentences: "Move out at 3 stacks," not "You should move out of the area once
  you have stacked 3 debuffs."
- Trigger word first: ability name / threshold / timer / key term leads the line —
  pattern-matching, not linear reading.
- One idea per line: no comma-chained multi-clause lines.
- Numbers, thresholds, timers, names: exact, never compressed.
- Whole section readable in ~4-5 sec.

## Process
1. Read the file.
2. Check for an existing `## TLDR` section near the top.
   - Exists -> replace just that section's content (idempotent re-run).
   - Doesn't exist -> insert a new `## TLDR` right after the title/frontmatter, before the body.
3. Leave everything below the TLDR exactly as it was.

Works on any .md file — plans, notes, guides.
````


### FILE: `.github/prompts/distill.prompt.md`

````md
---
mode: ask
description: 'Compress material into judgment instead of coverage — what a skim would miss, then the three or four points to lead with.'
tools: ['codebase', 'search']
---
# Distill

Input: `${input:material:a path, a topic, or nothing for this session}`.

Default summarization re-covers the material at lower resolution. This exercises judgment about
what matters instead. Two passes, in order — the order is the method.

## When to use this
- A doc, diff, research output, or session needs to become something presentable.
- The material is long enough that "what matters" is a real question.
- Skip when the answer is one fact, or when the ask is a faithful in-file summary of stated
  facts — that is `/tldr`.

## Procedure
1. **Scope it.** The argument, else the material in play this session. Name in one line what
   you read. Read it fully — a distillation of a skim is worthless.
2. **Observation pass.** List only the non-obvious:
   - what contradicts the headline or the stated conclusion,
   - what the numbers imply but the text does not say,
   - what is conspicuously absent given what is present,
   - what a skim reads straight past.
   Discard every line that restates the surface. "Nothing here a skim would miss" is a valid
   finding.
3. **Lead pass.** Collapse the observations into the **3-4 points you would open with**, ranked
   by what changes the reader's decision — not by what is most interesting or defensible. Four
   is the ceiling; three is usually right.
4. **Render.** Each lead point: one claim-first line, its supporting observation beneath it.
   Then one line naming what you deliberately left out.

## Constraints
- Never run the lead pass first. Selecting before inferring returns the obvious headline — the
  exact failure this exists to prevent.
- Output is the two lists, nothing else. No preamble, no restatement of the source, no recap.
- Length is downstream of selection, not a target.
- An observation you cannot source to the material is a guess — drop it.
- Writes nothing. Chat output only.
````


### FILE: `.github/prompts/grill.prompt.md`

````md
---
mode: ask
description: 'Grill the user relentlessly about a plan, decision, or idea to stress-test their thinking. Finds holes, does not help build.'
tools: []
---
# Grill

Stress-test the user's plan, decision, or idea by attacking its weakest points. Your job is to
find holes, not to help build — that comes later, if at all. Produces no artifact.

## Calibrate first
Open by asking one question: how hard do they want it, 1-5.
- 1-2: surface the obvious gaps, concede quickly when they answer well.
- 3: firm. Push on weak answers, move on from strong ones.
- 4-5: relentless. Assume every claim is load-bearing until proven otherwise. Don't let vague
  answers pass. Follow up until they either defend it or admit the gap.

Default to 3 if they don't say.

## How to grill
- One question at a time. Wait for the answer before the next.
- Go after the foundational assumptions first — the things that, if wrong, sink the whole plan.
- Each question targets one specific claim. No compound questions.
- When an answer is weak, follow up on the same point — don't move on to be polite.
- When an answer is genuinely good, say so briefly and move to the next weak point.
- Don't propose solutions mid-grill. If they ask for help fixing something, note it and keep
  grilling.
- No nitpicks.

## End with a verdict
When you've covered the major points (or they call it), stop and deliver:
- The 2-3 weakest points that survived scrutiny — where the plan is most exposed.
- For each: why it's a risk and what an answer would need to address.
- One line: does the plan hold up, or does it need rework before proceeding?

Be honest. If it's solid, say so. If it's not, don't soften it.
````


### FILE: `.github/prompts/code-review.prompt.md`

````md
---
mode: agent
description: "Review a diff or a plan's implementation for correctness, quality and plan adherence, bucketing findings by severity."
tools: ['codebase', 'search', 'editFiles', 'changes', 'runCommands']
---
# Code Review

Input: `${input:scope:full | plan <name> | running-review [report]}`.

Reviews on two axes together: **does it do what the plan said**, and **is it good code** (bugs,
security, tests, style). Findings are bucketed by severity, not dumped as a flat list. This
reports and re-verifies only — it never fixes anything.

## When to use this
- Before landing or merging, or to check an implementation against its plan doc.
- Not for architecture questions with no diff in hand — that's `/improve`.
- To *fix* what this finds, run `/resolve-review`.

## Assumptions (flag if wrong)
- Plans live at `specs/NNN-<slug>/plan.md`. If that path doesn't exist, search the project,
  then proceed as a pure quality review and say so.

## Scope
- `full` — the whole codebase, cross-checked against every `specs/*/plan.md`.
- `plan <name...>` — only the code the named plan(s) describe.
- `running-review [report]` — re-check fixes against an existing report. If `report` omitted,
  take the most recent with `Status: worked-on`; if none, say so and stop.

## Steps
1. **Resolve the project.** Confirm it's a git repo. If not, review files directly and say
   diff-based scoping is unavailable.
2. **Load context for the scope.**
   - `full` — read every `specs/*/plan.md`, then survey the codebase.
   - `plan <name...>` — read the plan doc(s) in full *first*: decisions, architecture,
     locked-in details. Then find the code, preferring `git diff` against the base branch.
   - `running-review` — read the existing report in full including any `## Resolution`
     section. Re-check each item marked Fixed against current code rather than trusting the
     note; re-examine anything Skipped or Deferred.
3. **Review both axes together.**
   - **Plan adherence** (only with a plan doc in hand) — flag both *deviations* and *plan
     gaps*. Let severity reflect your confidence.
   - **Quality** — correctness, security (injection, secrets, auth gaps, unsafe
     deserialization), test coverage for the changed logic, consistency with the codebase's
     conventions (not your own preferences).
4. **Bucket every finding.** **Blocking** (bugs, security, plan deviations that must be fixed
   before landing) / **Should-fix** (real but not launch-blocking) / **Nit** (style, naming,
   preference). Don't inflate severity to look thorough; don't bury real issues under nits.
5. **Write or update the report** at `specs/NNN-<slug>/review.md`:
   - `status:` + `updated:` header, scope at top, then counts by severity.
   - Findings grouped by severity, each with file:line, what's wrong, why it matters, a
     suggested fix.
   - `running-review` appends a `## Re-review — <date>` section — it doesn't rewrite history.
   - Set `status: closed` if no Blocking or Should-fix remain, else `open`.
   - Give a concise inline summary in chat too: the counts, then the Blocking items in full.
     Don't just say "see the report".

## What not to do
- Don't fix anything.
- No plan doc found for scope `plan <name>`: say so and stop; don't guess what the plan said.
- Nothing changed since the plan started: say so plainly rather than manufacturing findings.
````


### FILE: `.github/prompts/finalize.prompt.md`

````md
---
mode: agent
description: 'Prepare a branch for merge — done-checks, pre-merge docs, version bump, then a staged conventional commit.'
tools: ['codebase', 'search', 'editFiles', 'runCommands', 'changes']
---
# Finalize

Input: `${input:changetype:feature | fix | hotfix | chore | refactor, plus optional scope}`.

The land step. Run done-checks, update docs and version, produce a clean commit.

## When to use this
- Code is functionally complete and the review thread is closed.
- Skip if a regression is outstanding — fix it first.

## Procedure
1. **Determine change type** (infer from context, else ask):

   | Type | Semver | When |
   |---|---|---|
   | `feature` | minor | new user-facing capability |
   | `fix` / `hotfix` | patch | bug correction |
   | `chore` / `refactor` | patch or none | tooling / restructure, no behaviour change |

2. **Done checks** — verify before touching any file:
   - Planned work items resolved; no new open TODOs from this task.
   - Tests pass locally (the project's own test runner).
   - No debug/temp code (`console.log`, `debugger`, `pdb.set_trace`, `TODO(wip)`).
   - No merge conflicts; lint/type-checks pass if configured.
   If any check fails, stop and report what is blocking.
3. **Pre-merge documentation** — update only what exists in the repo:
   - CHANGELOG / RELEASE_NOTES — an entry under `## [Unreleased]` or the new version.
   - README — if setup, usage, or the feature list changed.
   - API / schema / migration docs — if public interfaces changed or the change is breaking.
4. **Version bump** — locate the version source (`package.json`, `pyproject.toml`, `VERSION`,
   ...), apply the semver increment, write it back to every file that must stay in sync,
   report `Version: X.Y.Z -> X.Y.Z'`. If the project tags manually, note the tag and skip file
   edits.
5. **Reconcile the plan index.** If a plan for this work exists, flip its status to
   `implemented` in the index it lives in — never rename or delete the plan file.
6. **Stage and commit — after the user confirms.** `git status --short` first; if unrelated
   files are dirty, stage by path and say what you left out. Show the staged paths and the
   message, then wait.
   ```
   <type>(<scope>): <short imperative summary>

   <optional body — what changed and why, wrapped at 72 chars>
   <optional footer — BREAKING CHANGE: ..., Closes #NNN>
   ```
   First line <= 72 chars, imperative mood. Never amend. Push only if asked.

## Done criteria
- All done-checks pass.
- Changelog and version files updated where they exist.
- Commit staged with a conventional message, user-confirmed.
- Plan index reconciled.
````


### FILE: `.github/prompts/resolve-review.prompt.md`

````md
---
mode: agent
description: "Work through a code-review report's findings and fix them in priority order, with confirmation on anything non-trivial."
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
# Resolve Review

Input: `${input:args:report path (specs/NNN-<slug>/review.md) and which: all | blocking | should-fix | nit}`.

Takes a `/code-review` report and works through its findings, fixing them one at a time in
priority order. This remediates — it does not re-judge whether something is a real issue. If a
finding looks wrong on inspection, say so and skip it rather than silently ignoring it or
arguing it away.

## Assumptions (flag if wrong)
- The report is an `open`-status `/code-review` output with findings grouped under **Blocking**
  / **Should-fix** / **Nit**, each with file:line, what's wrong, why it matters, a suggested
  fix.
- Fixing scope is limited to what's named in the finding — not an invitation to refactor
  around it.

## Arguments
- `report` — path to the review report. If omitted, look for the most recent
  `specs/*/review.md` with `status: open` and confirm it's the right one.
- `which` — `all` (default: Blocking, then Should-fix, then Nit) / `blocking` / `should-fix` /
  `nit`.

## Workflow
1. **Read the report.** Parse findings per severity tier, each with file:line and suggested
   fix.
2. **Work the findings** in tier order. Two review-specific points:
   - A finding that looks wrong on inspection — not a real bug, or the fix would break
     something else — is a *skip with reason*, not a silent pass.
   - For Nit, ask once up front — apply all, or list for the user to pick — rather than
     prompting per item.
3. **Set the report's `status:` to `worked-on`** and bump `updated:`. Never `closed` — only
   `/code-review` closes a thread, after re-checking the fixes.
4. **Offer to re-run `/code-review`** on the same scope to confirm the findings are actually
   resolved. Don't run it automatically — ask first.

## Boundaries
- Don't fix things the report didn't flag, even if you notice them — note them instead.
- Don't reduce a Blocking or Should-fix finding's severity to make it easier to skip.
- If more than a couple of findings need real design decisions rather than straightforward
  fixes, stop and flag that the report may need `/designit` rather than direct patching.
````


### FILE: `.github/prompts/implement.prompt.md`

````md
---
mode: agent
description: 'Execute a specs/ plan end to end, one step at a time, then hand off to finalize.'
tools: ['codebase', 'search', 'editFiles', 'runCommands', 'runTests']
---
# Implement a plan

Input: `${input:plan:plan path or target-project/module}`.

Executes a plan already authored by `/plan-doc` at `specs/NNN-<slug>/plan.md`, then hands the
finished work to `/finalize`. Follows the plan exactly; flags ambiguity instead of guessing.

## When to use this
- A `specs/NNN-<slug>/plan.md` exists with `status: authored`.
- Skip if no plan exists yet — run `/plan-doc` first.

## Procedure
1. Read the plan in full. Identify every deliverable. If the user named a plan, read it
   directly; otherwise take the one with `status: authored` from `specs/README.md` and confirm
   which to build.
2. **Work the plan's Steps in order, Do then Verify, one at a time.** On an ambiguous or
   conflicting step, stop and ask rather than guessing.
3. **Write tests alongside each unit**, matching the style already in the codebase (look at
   one existing test file first). Run them as part of that step's Verify.
4. **Close out via `/finalize`** — done-checks, changelog, version, plan-index flip to
   `implemented`, commit on confirm. Don't duplicate any of that here.

## What not to do
- Don't invent scope beyond the plan's Steps — new ideas go back to `/plan-doc`.
- Don't make architectural decisions mid-build — stop and ask.
- Don't skip a step's Verify because it "obviously works".
- Don't assert a function's return shape from memory — read it first. When the test is about
  *absence*, assert shape-independently (serialize the payload and search it).
````


### FILE: `.github/prompts/forge.prompt.md`

````md
---
mode: agent
description: 'Take raw idea notes and adversarially decide whether each should become a prompt file — fold, add, or drop — with an in-principle rating.'
tools: ['codebase', 'search', 'editFiles']
---
# Forge

Input: `${input:input:dir to scan (default docs/prompt-ideas/), or prose describing a revision to an existing prompt}`.

Turns raw ideas into prompt-file decisions. For each idea it models the strongest version of
the prompt implied, runs an internal Proposer/Skeptic debate, and renders a verdict plus a
rating.

> Ported from a Claude Code skill. "skill" == a `.github/prompts/*.prompt.md` file here;
> the registry is that directory. Adjust paths to your repo's convention.

## When to use this
- `docs/prompt-ideas/` has accumulated candidates and you want them triaged.
- **Revision mode** — a prose argument (not a scan dir) naming a change to what an existing
  prompt *does*: its procedure, triggers, tools, or a mis-calibration. No new idea file needed.
- Skip only for a pure wording fix — just make it.

## Procedure
1. **Resolve the input.** If the argument is prose describing a change to an existing prompt,
   this is **revision mode**: skip the scan, model the target prompt as it stands and the
   proposed change, run steps 2-4 on *the change*, write the report section, and on confirm
   apply the edit directly. Otherwise scan the argument dir (else `docs/prompt-ideas/`) for
   `*.md` and process each in order.
2. **Proposer pass** — model the strongest prompt the idea implies: name, one-line purpose,
   trigger phrases, the procedure it would run, the artifact or outcome it produces, the
   recurring need it serves. Steelman it. Write this case into the report before the Skeptic
   pass.
3. **Skeptic pass** — assume the prompt should *not* exist; make the idea earn its place.
   Attack on four axes:
   - **Overlap** — against every existing `.github/prompts/*.prompt.md`. Name any prompt it
     duplicates or heavily shares discipline with.
   - **Realness** — is the need recurring or a one-off? Cite evidence.
   - **Prompt-shaped** — is this a reusable *procedure*, or a preference / fact / one-time task
     that belongs in `copilot-instructions.md`?
   - **Context cost** — does an always-visible `description` for this pay for itself?
4. **Synthesis** — reconcile the two passes, citing named Proposer and Skeptic points (a named
   overlap must be addressed). Apply the rule:
   - Distinctness <= 2 -> **fold into `<existing>`** — unless Recurrence >= 4 *and* folding
     would push the host past ~120 lines, then **add**.
   - Prompt-fit <= 2 **or** Recurrence <= 2 -> **drop** (say which axis, and where the content
     should go instead).
   - Otherwise -> **add as new**.
5. **Rating, in principle** — score independent of the verdict. Five axes, 1-5, one line of
   justification each:

   | Axis | 1 | 5 |
   |---|---|---|
   | Recurrence | seen once | arises weekly |
   | Distinctness | ~duplicate | no neighbour |
   | Prompt-fit | belongs in instructions | clearly a repeatable procedure |
   | Scope tightness | vague / broad | single crisp trigger->outcome |
   | Context cost | heavy for niche value | cheap or high-value |
6. **Write the report** to `docs/prompt-ideas/_assessments/<YYYY-MM-DD>.md` — one file per run,
   each idea a section: modeled prompt, Proposer case, Skeptic case, verdict, rating.
7. **Act on confirm, per item:**
   - **add** — write `.github/prompts/<name>.prompt.md` to the authoring standard.
   - **fold** — show the exact edit (target prompt, section, added text); apply on yes.
   - **drop** — record the reason.
   Then move every processed idea file to `docs/prompt-ideas/_processed/` with the verdict
   appended. Never delete an idea file.

## Constraints
- Proposer's full case is written to the report before the Skeptic pass begins.
- The Skeptic argues from "this should not exist"; a weak defence is a finding, not a pass.
- Synthesis must address every overlap the Skeptic named.
- `add` produces a first draft; a real design pass is `/designit`.
````


### FILE: `.github/prompts/designit.prompt.md`

````md
---
mode: agent
description: 'Iteratively drill a feature, idea or requirement into a locked spec, then hand it to /plan-doc. No coding.'
tools: ['codebase', 'search', 'editFiles']
---
# Designit

Starts from a single high-level plan and progressively zooms in, one round at a time, until
the details are locked. **No coding** — the output is a decision, not an implementation.

## When to use this
- Before building anything whose shape isn't already obvious.
- Skip for a change you could describe fully in one sentence — go straight to the edit, or to
  `/plan-doc` if it still deserves a record.

## Procedure
1. **State your assumptions upfront**, and ask clarifying questions rather than guessing at
   anything that would change the design. Read the codebase to ground them — do not guess the
   tech stack.
2. **Draft the design at one level of detail**, then present it and stop. This is a human
   gate. The user decides: **redo** / **confirm and continue** (zoom in one level) / **confirm
   and finalize**.
3. **Repeat** until every Critical/Major decision is settled or the user says "confirm and
   finalize". Each round adds real resolution — structure, boundaries, libraries, the
   decisions and their reasons — never a restatement of the last.
4. **On finalize, write the spec** to `specs/NNN-<slug>/spec.md`, `status: accepted`. Take
   `NNN` from the `specs/` index if it exists. Then hand off: `/plan-doc` reads this spec and
   writes the plan.

## The spec must carry
- **Problem** — why the work exists, what is currently true, the constraint that forced the
  design.
- **Considered Approaches** and the **Decision** with its reason — the choices that were
  actually contested.
- **Design** — enough detail to plan against without re-deriving it.
- **Non-Goals** — what was deliberately left out, so it isn't re-litigated mid-build.

## What not to do
- Don't write code, and don't edit the target files "to check" — read only.
- Don't advance a round without the user's explicit word; "looks good" on one level isn't
  approval of the next.
- Don't leave a decision whose consequences you haven't drilled into.
````
