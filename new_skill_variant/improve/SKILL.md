---
name: improve
description: "Measure a codebase or area for improvement opportunities using four architecture checks. Produces a prioritized findings report with concrete, actionable proposals — no changes applied. Use when a file keeps coming up in changes, when something feels hard to touch, or when asked to review/improve architecture. Trigger on: improve, review architecture, find improvements, what's wrong with, refactor candidates, code quality, where should I start."
argument-hint: "File, directory, or area to measure (omit to find hot spots automatically)"
tools: [Read, Grep, Glob, Bash, Todo]
---

# Improve

Measures code against four architecture checks and produces a prioritized findings report.
**No changes are applied.** The output is a set of concrete proposals for the user to act on.

## The Four Checks

Check in this order — upstream problems cause downstream symptoms, so fix the root, not the symptom.

| # | Check | The Question |
|---|-------|-------------|
| 1 | **Layout** | Can you find things without tribal knowledge? |
| 2 | **Isolation** | Does each module do one thing without entangling others? |
| 3 | **Interfaces** | Does the public surface fully cover callers without exposing internals? |
| 4 | **Extensibility** | Does adding a new case fit in one obvious place? |

Tests and performance aren't separate checks — they tend to follow once these four hold.

## Procedure

### Step 1 — Find the Target

If the user named a file or area, use it. Otherwise, find hot spots:

```bash
git log --oneline --since="90 days ago" -- "*.py" "*.ts" "*.go" | \
  awk '{print $NF}' | sort | uniq -c | sort -rn | head -20
```

Files that keep recurring in commits are where change pain is actually felt. Pick 1-3 candidates — not more. If everything looks broken, the scope is too wide; narrow it.

### Step 2 — Measure Against the Checks

Read the candidate(s). For each check, look for **concrete signals** — not feelings:

#### 1. Layout
Signals of a problem:
- Directory name doesn't match what's inside
- A file does two unrelated things (signals: long file, mixed import groups, unrelated test coverage)
- Finding a function requires knowing where it was put, not where it logically belongs
- Measure: file length outliers (`wc -l`), files with imports from distant unrelated modules

#### 2. Isolation
Signals of a problem:
- Module imports siblings it shouldn't need (`grep -r "from ../sibling"`)
- Logic copy-pasted across files instead of shared (`grep` for structural duplicates)
- A change in module A requires a change in module B for unrelated reasons
- Measure: import fan-out (how many modules does this file import?), circular dependencies

#### 3. Interfaces
Signals of a problem:
- Callers access `._private` attributes or internal state
- The public API requires callers to do setup that the module should handle
- Adding a caller requires reading the implementation, not just the signature
- Measure: count of `._` accesses from outside, parameter lists > 4 args (a sign of missing abstraction)

#### 4. Extensibility
Signals of a problem:
- Adding a new case requires editing N files for a single logical change
- `if/elif` chains or `switch` on type/kind that grows with each feature
- Measure: pick the most plausible next addition and trace every file that would need changing

### Step 3 — Score and Prioritize

For each finding, assign:

| Severity | Meaning |
|----------|---------|
| **High** | Active pain — this check failing is causing friction in real changes today |
| **Med** | Latent risk — not painful yet but the next feature will hit it |
| **Low** | Worth noting but not worth acting on without another trigger |

### Step 4 — Report Findings

Present findings in this format, ordered by severity. Stop at **2-3 findings** — a long list means scope was too wide.

---

**Finding 1** · `path/to/file.py` · Isolation · **High**

> _What's broken:_ `auth.py` imports from `billing.py` only to format an error message. These modules have no other relationship.
>
> _Evidence:_ `grep -n "from billing" auth.py` → line 47
>
> _Proposed fix:_ Move the error formatter to `errors.py` (shared). Both modules import from there.
>
> _What gets simpler:_ `billing.py` can be changed without risk of breaking auth. Tests become independent.

---

**Finding 2** · `path/to/routes.py` · Extensibility · **Med**

> _What's broken:_ Adding a new route type requires editing the `if/elif` chain at line 83 **and** the registration dict at line 12.
>
> _Evidence:_ Last 3 route additions each touched both locations (git log).
>
> _Proposed fix:_ Replace with a registration decorator — each route type self-registers.
>
> _What gets simpler:_ New route types are added in one file, one place.

---

### Step 5 — Stop

Present the report and stop. Do not refactor unprompted. Let the user decide which findings to act on — hand off to `/plan-doc` or `/implement` for execution.

## Constraints
- Propose 1-3 findings maximum; if more appear, pick the highest-severity ones
- Every finding must have direct evidence (a line number, a grep result, a git log entry)
- Never fix speculatively — if nothing's actually hurting yet, say so and skip it
- Stop at the first broken check per file — fix the root, not the downstream symptom
