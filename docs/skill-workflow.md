# Skills workflow

A map, not a skill. Nothing here fires automatically — each step is invoked by hand.

```
grillme          → Discovery
/notice          → capture friction as it happens, during any work
   ↓ (reviewed by hand, no fixed schedule)
/planit           → drill a feature/idea into a locked plan (redo / confirm and continue / confirm and finalize)
   ↓ (only after "confirm and finalize")
/plan-doc         → write the locked plan to docs/plans/NNN-slug.md + index row
   ↓ (build happens)
/implement        →  implement the plans one by one
   ↓ (plan implemented)
/code-review      → findings → docs/reviews/<report>.md, Status: open
   ↕ (loop until closed)
/resolve-review   → fixes the findings, Status: worked-on
   ↓ (/code-review running-review → Status: closed)
/land-feature     →  update completed actions
```

The review loop is a handshake on the report's `Status:` field — `open` (findings
outstanding, written by `/code-review`) → `worked-on` (fixes applied, written by
`/resolve-review`) → `closed` (re-checked clean, written by `/code-review`, terminal).
Neither skill writes the other's status, and only `closed` forwards to `/land-feature`.

## Utility
```
/handoff          → Hands off the session via brief-mcp
/resume           → Resumes the handedoff session via brief-mcp

/prune            → condense *.md logs; git is the real archive
/diagnose         → discipline to reach for when something breaks (not a step, a stance)

/prototype        → throwaway script to answer one design/logic question, if needed mid-build
/prototype-ui     → throwaway UI variants to answer a look-and-feel question, if needed mid-build
   ↓ (landed)

/query-db
```



## When each one fires

- **`/notice`** — no trigger, just habit. Something recurs → one line in `~/Documents/code/claude_settings/docs/notice.md`.
- **`/planit`** — explicit only (`disable-model-invocation: true`). You call it when a feature/idea needs drilling into before building.
- **`/plan-doc`** — fires after `planit` finalizes, or on its own before `ExitPlanMode` for anything bigger than a single edit.
- **`/diagnose`** — not really "called." It's the standard to hold yourself to whenever debugging, described not scripted.
- **`/prototype` / `/prototype-ui`** — reach for either mid-build, whenever a question needs proving before committing to an approach. Independent of the plan/build chain — can happen anytime.
- **`/code-review` / `/resolve-review`** — explicit only, after a build and before landing. `/code-review` reports and never fixes; `/resolve-review` fixes and never closes. For architecture with no diff in hand it's `/improve` instead; to apply routine cleanups directly it's the built-in `/simplify`.
- **`/prune`** — periodic housekeeping on the markdown logs. Not gated on anything else finishing.

## Not automated, on purpose

No skill here calls another. You decide when to move from one to the next — that's deliberate, so the sequence stays something you actually know, not something a wrapper does for you.