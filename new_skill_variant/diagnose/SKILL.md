---
name: diagnose
description: "Systematic, evidence-based debugging for failures, errors, regressions, and unexpected behavior. Use when asked to diagnose, debug, find the cause of, or investigate a failure, error, crash, or bad output. Trigger on: diagnose, debug, why is X failing, what's causing, find the bug, investigate, root cause."
argument-hint: "Symptom or error to investigate (e.g. 'login returns 500', 'tests flaky on CI')"
tools: [Read, Grep, Glob, Bash, Todo]
---

# Diagnose

Find the actual cause of a failure through direct evidence. Never conclude a cause from
a plausible story alone — get a log line, a repro, a timestamp, or a diff that
proves it. Findings that can't be evidenced are hypotheses, not conclusions.

## Core Rules

- **Reproduce before anything else.** A failure you can't trigger is not yet diagnosed.
- **One hypothesis at a time.** Test the most likely cause first; eliminate before moving on.
- **Symptoms that don't unify under one cause get split and treated separately.** Do not force a single narrative.
- **Hold conclusions loosely.** New evidence can invalidate a "ruled out" theory — revisit if it does.
- **Scope is read-only.** Fixes are out of scope here; note them and stop. (`/implement` or `/plan-doc` handles fixes.)

## Procedure

### Step 0 — Clarify Target

If ambiguous, ask once:
- **Local** — investigate on this machine directly (default)
- **Server** — investigate over SSH; read-only only, no changes

### Step 1 — Establish Ground Truth

1. Reproduce the failure yourself. If you cannot reproduce it, say so and ask for a reproduction recipe before continuing.
2. Record the **exact** failing output: error message, exit code, log lines, stack trace.
3. Note the **scope**: what consistently fails, what sometimes fails, what works.

```
Failing: <exact error / bad output>
Scope:   <always | sometimes | only on CI | only in prod>
Since:   <last known good state, if known>
```

### Step 2 — Collect Symptoms

Without touching any logic yet, gather:

- **Logs** — error messages with timestamps, stack traces, surrounding context
- **State** — env vars, config, inputs that were in play
- **Recent changes** — git log since last known good (`git log --oneline HEAD~10`)
- **Isolation** — does it fail with minimal input? in a fresh environment?

List symptoms as facts, not interpretations. "Returns 500" is a fact. "The auth is broken" is an interpretation.

### Step 3 — Form Hypotheses

Based on symptoms, list candidate causes, most likely first:

```
H1: <specific, testable claim about root cause>
H2: <next candidate>
H3: ...
```

A good hypothesis is falsifiable: it predicts something you can check.

### Step 4 — Test Hypotheses (One at a Time)

For each hypothesis, starting with H1:

1. **Predict** what you'd see if this hypothesis were true.
2. **Check** — run a command, read a file, search a log — to confirm or refute.
3. **Record** the result as `CONFIRMED`, `REFUTED`, or `INCONCLUSIVE`.
4. Move to the next hypothesis only after the current one is resolved.

Do not skip ahead. Do not test multiple hypotheses simultaneously.

#### Evidence Collection Patterns

| What to check | How |
|---------------|-----|
| Recent code changes | `git log --oneline -20`, `git diff HEAD~N` |
| Error in logs | `grep -n "ERROR\|Exception\|Traceback" <logfile>` |
| Env / config state | read config files, check env vars |
| Dependency versions | `pip list`, `npm list`, `cat lock file` |
| Failing test details | run the specific failing test with verbose output |
| Data / input causing failure | isolate the minimal input that triggers it |

### Step 5 — Confirm Root Cause

Before concluding, verify:

- [ ] You have direct evidence (not just a plausible story) for the cause
- [ ] The evidence explains **all** recorded symptoms, or you've accounted for why it doesn't
- [ ] You can describe the causal chain: "X happens because Y, which causes Z"

If multiple independent causes are present, list them separately — do not merge them into one narrative.

### Step 6 — Report Findings

```
## Diagnosis

**Root Cause:** <one sentence — the actual cause, not the symptom>

**Evidence:**
- <log line / file / command output that proves it>
- <second piece of evidence if relevant>

**Causal Chain:**
<X> → <Y> → <observed failure>

**Scope:** <what is affected, what is not>

**Suggested Fix:** <what needs to change — implementation is out of scope here>

**Still Unknown:** <anything that remains unresolved or unconfirmed>
```

## Done Criteria
- Root cause is identified with direct evidence
- Causal chain is stated
- Suggested fix is noted (not implemented)
- Any remaining unknowns are documented
