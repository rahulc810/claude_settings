---
name: designit
description: "Brainstorm and design a feature, system, or change before any code is written. Iteratively refines from idea to locked design doc. Use when something needs deciding and documenting before building. Trigger on: design this, brainstorm, design doc, architecture for, how should we build, what's the approach, plan this feature."
argument-hint: "Feature, idea, or problem to design (e.g. 'OAuth2 login flow', 'cache invalidation strategy')"
tools: [Read, Grep, Glob, Write, Edit, Todo]
---

# Designit

Turns a vague idea into a locked design document by zooming in one round at a time.
No code is written. The output is a decision and a doc, not an implementation.

## When to Use
- Before building anything whose shape isn't already obvious
- When multiple approaches exist and a choice needs to be made and recorded
- Skip for a change fully describable in one sentence — go straight to the edit

## Procedure

### Round 0 — Orient

Before drafting anything:
1. Read the relevant parts of the codebase (entry points, interfaces, existing patterns). Do not guess at the tech stack.
2. State your assumptions explicitly.
3. Ask clarifying questions for anything that would change the design. Stop and wait for answers — do not draft around unknowns.

### Rounds 1…N — Iterate

Each round:
1. Draft the design **at one level of detail** and present it.
2. Stop. The user responds with one of:
   - **Redo** — revise the current level
   - **Continue** — zoom in one level deeper
   - **Finalize** — the design is locked; proceed to write the doc
3. Each round must add real resolution: structure, boundaries, library choices, tradeoffs, decisions and their reasons. Do not restate the previous round.

Levels (use as many as needed):
- **L1 — Shape**: high-level approach, major components, what it is *not*
- **L2 — Structure**: module/service breakdown, data model sketch, key interfaces
- **L3 — Detail**: exact types, call flows, error paths, config, migration steps

### Final Step — Write the Design Doc

Only after "Finalize". Create the file at `docs/designs/<slug>.md` (create the folder if it doesn't exist).

#### Design Doc Template

```markdown
# <Title>

**Status:** Draft | Accepted | Superseded  
**Date:** YYYY-MM-DD  
**Author(s):** <names or "AI-assisted">

## Problem

<Why this work exists. What is currently true. The constraint or trigger.>

## Goals

- <What success looks like — measurable where possible>

## Non-Goals

<What is deliberately out of scope so it isn't re-litigated later.>

## Considered Approaches

### Option A — <Name>
<Description, pros, cons>

### Option B — <Name>
<Description, pros, cons>

## Decision

**Chosen:** Option X  
**Reason:** <The reason it went this way, not just that it did>

## Design

<Architecture, data model, interfaces, call flows — enough detail to implement without re-deriving>

## Implementation Steps

| # | What | Files / Scope | Verify |
|---|------|--------------|--------|
| 1 | ... | ... | `<command that proves it works>` |

## Open Questions

<Anything still unresolved that implementation will surface>
```

Fill in every section. Do not leave placeholders. If a section genuinely does not apply, write "N/A — <one-line reason>".

## Constraints
- Read the codebase; do not edit it
- Do not advance a round without explicit user confirmation
- "Looks good" on one level is not approval of the next
- Every Implementation Step must have a runnable Verify command
