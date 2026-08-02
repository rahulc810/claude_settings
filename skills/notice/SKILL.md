---
name: notice
description: Note a recurring friction, correction, or workflow pattern during work, for later review as a possible new or improved skill. Use when a correction, repeated workaround, or "I always do it this way" moment comes up mid-task.
allowed-tools: Read, Edit
---

# Notice

Most skill improvements come from noticing friction during real work, not from sitting down to write a skill in isolation. This captures that noticing, cheaply, without turning it into process.

## When to use this

When something recurs — a correction you give more than once, a workaround you reach for again, a rule you wish an existing skill already had — jot it down. One-off corrections that clearly won't recur aren't worth logging.

## How

Append a line to `docs/notice.md` 

```
- <date>: <what happened> → <what it might mean for a skill>
```

Keep it to one line. No status field, no numbering, no format beyond that — this is a scratch note, not a ledger. If it collides with another entry or gets duplicated, that's harmless; delete duplicates next time you look at the file.

## Reviewing

Periodically — whenever you're touching skills anyway, no fixed schedule — skim the file. For each note, decide by hand:

- Recurred more than once, or generalizes cleanly → worth a skill change. Make it directly, or run `/planit` first if it needs real design.
- One-off, or already covered → delete the line.

Clear out actioned or dead lines as you go. The file should stay short enough to read in one pass.