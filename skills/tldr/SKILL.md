---
name: tldr
description: Add a condensed TLDR section to the top of any markdown file, readable in a 4-5 second glance, without cutting or rewriting the existing body. Use when asked to add/update a TLDR, make a doc skimmable, or make a guide glance-readable — works on any .md file, not just WoW guides. Re-runnable: updates an existing TLDR in place rather than duplicating it.
allowed-tools: Read, Edit
model: claude-sonnet-4-6
---

# TLDR

Adds a glance-readable summary on top. Never touches the rest of the file.

## Rule

The existing body ("regular" section) is never cut, rewritten, or re-leveled — not even lightly. Only a `## TLDR` section is added or updated. If you find yourself trimming the body to make the file shorter, stop — that's not this skill's job.

## TLDR format

- Fragments over sentences: "Move out at 3 stacks," not "You should move out of the area once you have stacked 3 debuffs."
- Trigger word first: ability name / boss % / timer / key term leads the line — pattern-matching, not linear reading.
- One idea per line: no comma-chained multi-clause lines.
- Numbers, thresholds, timers, names: exact, never compressed.
- Whole section readable in ~4-5 sec.

## Process

1. Read the file.
2. Check for an existing `## TLDR` section near the top.
   - Exists -> replace just that section's content (idempotent re-run, e.g. after nugget-muncher updates the body).
   - Doesn't exist -> insert a new `## TLDR` section right after the title/frontmatter, before the body.
3. Leave everything below the TLDR exactly as it was.

## Scope

Works on any .md file, not just guides — plans, briefs, notes all fair game when asked.