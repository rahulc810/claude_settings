---
mode: ask
description: 'Compress material into judgment instead of coverage — what a skim would miss, then the three or four points to lead with.'
tools: ['codebase', 'search']
---
# Distill

Input: `${input:material:a path, a topic, or nothing for this session}`.

Default summarization re-covers the material at lower resolution. This exercises judgment about
what matters instead. Two passes, in order — the order is the method.

## When to use this
- A doc, diff, research output, or session needs to become something presentable.
- The material is long enough that "what matters" is a real question.
- Skip when the answer is one fact, or when the ask is a faithful in-file summary of stated
  facts — that is `/tldr`.

## Procedure
1. **Scope it.** The argument, else the material in play this session. Name in one line what
   you read. Read it fully — a distillation of a skim is worthless.
2. **Observation pass.** List only the non-obvious:
   - what contradicts the headline or the stated conclusion,
   - what the numbers imply but the text does not say,
   - what is conspicuously absent given what is present,
   - what a skim reads straight past.
   Discard every line that restates the surface. "Nothing here a skim would miss" is a valid
   finding.
3. **Lead pass.** Collapse the observations into the **3-4 points you would open with**, ranked
   by what changes the reader's decision — not by what is most interesting or defensible. Four
   is the ceiling; three is usually right.
4. **Render.** Each lead point: one claim-first line, its supporting observation beneath it.
   Then one line naming what you deliberately left out.

## Constraints
- Never run the lead pass first. Selecting before inferring returns the obvious headline — the
  exact failure this exists to prevent.
- Output is the two lists, nothing else. No preamble, no restatement of the source, no recap.
- Length is downstream of selection, not a target.
- An observation you cannot source to the material is a guess — drop it.
- Writes nothing. Chat output only.
