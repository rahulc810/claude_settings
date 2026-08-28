# skill-ideas/

Raw candidates for new or improved skills. One idea per `*.md` file — freeform: a paragraph,
a sketched procedure, a pasted draft `SKILL.md`, whatever captures the intent.

`/forge` scans `docs/skill-ideas/*.md` (non-recursive), models the strongest version of
each, adversarially decides **fold into an existing skill / add as new / drop**, and
rates it. On confirm it writes the `add` drafts and applies the `fold` diffs.

- `_assessments/<date>.md` — `/forge`'s reports. Generated; don't hand-edit.
- `_processed/<idea>.md` — ideas that have been through `/forge`, verdict appended.
  Moved here automatically, never deleted.

To promote a `docs/notice.md` friction line: copy it into a new file here, add whatever
context you have, then run `/forge`.
