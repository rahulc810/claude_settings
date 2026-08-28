status: authored
updated: YYYY-MM-DD
spec: specs/NNN-<slug>/spec.md

# Plan NNN — <Title>

## Context

<Why this work exists, what is currently true in the code, and the invariant or
constraint that forced the design. Name the specific files and behaviours that are the
starting point.>

## Decisions

<The choices that were actually contested, each with the reason it went that way. Omit
if there was no spec — uncontested choices don't need listing.>

## Out of Scope

<What is deliberately excluded. Be specific — vague exclusions get re-litigated.>

## Steps

### 1. <Imperative title — what this step achieves>

**Files**
- `path/to/file` — what role it plays

**Do**
The change, precisely enough to execute without re-deriving it: the function/signature to
add or modify, exact behaviour, any config keys or constants introduced.

**Verify**
```bash
<exact command>
```
Expected: `<exact output or exit code that means success>`

---

### 2. <Next step>
...
