---
name: land-feature
description: Close out landed work — append the docs/COMPLETE_ACTIONS.md entry, reconcile CLAUDE.md invariants, update README.md and docs/plans/README.md status. Use when work is finished and the user says "done", "ship it", "land this", "log this", "wrap up", or asks for a COMPLETE_ACTIONS entry.
allowed-tools: Read, Edit, Write, Bash, Grep
---

# Landing a feature

`CLAUDE.md` states the contract: *"Feature lands → a `COMPLETE_ACTIONS` entry.
Invariant changes → a `CLAUDE.md` edit. Nothing else goes in `CLAUDE.md`; it is not a
changelog."* This skill executes that contract — it doesn't re-derive it.

> **Orient first:** read the target repo's `CLAUDE.md` and its `docs/plans/README.md`
> header — they govern this repo's doc set, invariants and plan-status vocabulary, not
> devkit's.

## When to use this

- Work is finished and its tests pass, whether or not a plan doc drove it.
- Skip if the work isn't done — an inherited test failure is fine (see step 6), a
  regression is not.

## Steps

**1. Read the ledger's tail before writing.** Match the existing format — don't invent a
heading style.

```bash
tail -30 docs/COMPLETE_ACTIONS.md
```

**2. Append one entry.** Newest last. The shape, matching every existing entry:

```markdown
## <short title — what a reader would search for> (YYYY-MM-DD)
- `<module>/<class>/<function>`: what it now does, in the present tense.
- Behaviour that is load-bearing elsewhere (a default, a refusal, a pin) stated explicitly.
- Consumers migrated / deploy files added, if any.
```

Rules:
- Append only. Never rewrite or reorder existing entries.
- One entry per landed feature, not per commit.
- Date is today's real date, not the date the work started.
- Describe the end state, not the diff. "`connect()` opens WAL with a 5s timeout", not
  "changed connect() to add a timeout".

**3. Decide whether an invariant moved.** Edit `CLAUDE.md` only if a numbered
invariant's text is now false, or a new module belongs in the map — a bug fix, a
refactor, or a new tool on an existing tenant is **no edit**.

#### Devkit specifics
| Change | CLAUDE.md action |
|---|---|
| New module or file under `src/` | add a line to the module map |
| Trust model, listener topology, or OAuth flow changed | rewrite the affected invariant in 4–8 **and** confirm a fail-closed test exists |
| New or renamed dependency/extra in `pyproject.toml` | update invariant 1 |
| `.env` cascade precedence or tier selection changed | update invariant 2 |
| Default DB directory changed | update invariant 3 |
| Anything else (bug fix, refactor, new tool on an existing tenant) | **no edit** |

**4. Update `README.md`** only if the *public surface* changed — a new public function,
a changed signature, a new dependency/entry point, or a change to the documented way of
extending the project. Internal refactors don't touch it. While you're in there, fix any
statement the change has made false, even if it predates your work — a stale README is
how the next person gets it wrong.

*Devkit specifics:* a new extra, a new `[project.scripts]` entry, or a new step in "how
to write a tenant".

**5. Reconcile the plan index.** If `docs/plans/` holds a plan for this work, flip its
row in `docs/plans/README.md` to **implemented** — status lives in that table only,
never rename or delete the plan file.

**6. Run the tests before declaring it landed.** Use the project's own interpreter —
`./.venv/bin/python -m pytest -q` when `./.venv` exists, not bare `python`.

If anything fails, classify before reporting: `git stash`, re-run, `git stash pop`.
- **Inherited** — present on the clean tree. Doesn't block the ledger entry: report it,
  say you verified it pre-exists, don't fix it — that's new scope.
- **Regression** — appears only with the change. Fix it; don't write the ledger entry
  until it passes.

```bash
./.venv/bin/python -m pytest -q    # or: python -m pytest -q, if the repo has no .venv
```

**7. Commit — after the user confirms, always.** Run `git status --short` first; if files
unrelated to this work are dirty or untracked, stage by path instead of `git add -A` and
say what you left out. Then show the staged paths and the commit message and wait, however
this skill was invoked. Never amend.

```
git add <path> ...
git commit -m "feat/bug/chore: <Action summary>"
```

Push only if the user asks, or has already said to push this work.

## What not to do

- Don't rewrite or reorder existing ledger entries — the file is append-only.
- Don't edit `CLAUDE.md` for a bug fix, a refactor, or a new tool on an existing tenant.
- Don't write the ledger entry while a regression is outstanding.
- Don't rename or delete a plan file to record its status.