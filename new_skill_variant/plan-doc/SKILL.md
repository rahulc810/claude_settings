---
name: plan-doc
description: "Translate a design doc or feature description into a numbered, deterministic implementation plan. Use after /designit finalizes, or when a feature needs a step-by-step execution guide detailed enough for a junior model to follow without ambiguity. Trigger on: plan this, write a plan, implementation plan, plan-doc, create a plan, step-by-step plan, plan from design."
argument-hint: "Path to design doc, or feature description if no design doc exists"
tools: [Read, Grep, Glob, Write, Edit, Bash, Todo]
---

# Plan Doc

Translates a design (or raw feature description) into a numbered implementation plan detailed
enough that a junior model can execute every step without re-deriving anything.

The output is **deterministic**: no vague verbs, no "figure it out", no missing file paths,
no verify steps that don't specify expected output.

## When to Use
- Typicall, after `/designit` produces a design doc
- When you need a written plan before starting any code
- When you want a junior model (or future you) to be able to execute the work unambiguously
- Skip for a single-file change nobody needs to re-read

## Procedure

### Step 1 — Read Sources

Gather everything needed before writing a single line of the plan:

1. Read the design doc if one exists (`docs/designs/`, argument path, or context).
2. Read `docs/plans/README.md` to find the next plan number.
3. Read the relevant source files — entry points, interfaces, tests — to know current state.
   Never describe a change without first reading the file it touches.

### Step 2 — Draft the Plan

Write the plan in the structure below. Every step must be concrete enough that someone
with no prior context on this feature can execute it correctly.

#### Plan File Structure

```markdown
# Plan NNN — <Title>

**Status:** authored  
**Date:** YYYY-MM-DD  
**Design doc:** docs/designs/<slug>.md  ← omit if no design doc

## Context

<Why this work exists. What is currently true in the codebase. The constraint or trigger.
Name the specific files and behaviors that are the starting point.>

## Decisions

<The choices already locked in the design, each with the reason. A reader six months
from now needs the *why*, which the code will not carry. Omit this section if there
was no design doc — decisions that weren't contested don't need to be listed.>

## Out of Scope

<What is deliberately excluded. Be specific — vague exclusions get re-litigated.>

## Steps

### 1. <Imperative title — what this step achieves>

**Files**
- `path/to/file.py` — what role it plays

**Do**
Exact description of the change. Include:
- The function/class/method to add or modify
- The signature, types, and return value
- Exact behavior (not "handle errors" — "raise ValueError if X is None")
- Any config keys, env vars, or constants introduced

**Verify**
```bash
<exact command to run>
```
Expected: `<exact output or exit code that means success>`

---

### 2. <Next step>
...
```

#### Rules for Each Step
- **One concern per step.** Don't bundle "add the model + wire up the route + write tests" into one step.
- **Files are exact paths,** not "somewhere in src/". Read the codebase first.
- **Do is precise enough to copy-paste intent.** If it says "add a function", it names the function, its parameters, and its return type.
- **Verify is runnable and has expected output.** `pytest tests/test_auth.py::test_login -q` → `1 passed`. Not "tests should pass".
- **Dependencies are explicit.** If Step 3 requires Step 2's output, say so.

### Step 3 — Review Gate

Present the full plan (not a summary — the actual plan text) and ask:

> **Does this plan look right?**  
> Reply **yes** to write it to disk, or describe what to change.

Do not write any files until you receive confirmation.

### Step 4 — Write to Disk

After confirmation:

1. Write `docs/plans/NNN-slug.md` with the plan content.
2. Add an index row to `docs/plans/README.md`:

   | # | Title | Status | Notes |
   |---|-------|--------|-------|
   | NNN | Title | authored | |

   Status vocabulary:

   | Status | Means |
   |--------|-------|
   | **authored** | Written, not started |
   | **implemented** | Landed — matching `docs/COMPLETE_ACTIONS.md` entry exists |
   | **superseded** | Replaced — name the successor in Notes |
   | **abandoned** | Dead — say why in Notes |

3. Report: `Written: docs/plans/NNN-slug.md`

## Constraints
- Never write the plan file before the review gate
- Never number a plan from `ls` — count from the index (abandoned plans keep their number)
- Never write a Verify step that can't actually be run
- Never flip a plan to **implemented** — that is `/finalize`'s job
- Never rename or delete plan files; status changes happen only in the index row
