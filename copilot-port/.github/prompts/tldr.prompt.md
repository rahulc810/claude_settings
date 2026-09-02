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
