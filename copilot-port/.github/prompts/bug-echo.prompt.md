---
mode: agent
description: 'After a bug is fixed, characterize it as a code pattern and hunt the codebase for structural twins, ranked by confidence. Reports only, never fixes.'
tools: ['codebase', 'search', 'changes']
---
# Bug Echo

The bug you just fixed is rarely the only one of its kind. Ordinary review checks whether code
is wrong on its own terms — it has no reason to connect one file's defect to the same mistake
three files away. This does exactly that connection, and nothing else. It never edits; to fix
what it finds, hand the list to `/resolve-review` or work it directly.

## When to use this
- Right after fixing a bug that could plausibly be a *class* — a missing guard, a wrong
  argument form, an absent platform affordance, a copy-paste that drifted.
- Skip for a genuinely one-off bug (a typo, a wrong constant used in exactly one place).
- Not a general audit — for that use `/code-review` or `/improve`.

## Procedure
1. **Characterize the fixed bug as a pattern.** One sentence naming the wrong *shape*, not the
   symptom: "a modal opened without a dismiss control", "a helper called with a positional arg
   that later became keyword-only", "a derived table read as evidence without a uniform-result
   check". If you can't state the shape, there's no pattern to echo — stop.
2. **Derive search terms for the shape** — the anti-pattern's tokens, the call that should be
   present but isn't, the construct that's misused. Plan several searches: the bare name, the
   qualified form, the surrounding idiom.
3. **Sweep the codebase in one parallel batch.** Cast wider than you think you need; step 4 is
   the filter.
4. **Read every hit.** A match is only a sibling if the *same defect* is actually present —
   local context (a guard one frame up, a different code path, a caller that can't hit it)
   often saves a look-alike. Grep counts are not findings.
5. **Rank what survives.** Per site: `file:line`, one line on why it's the same bug, and a tag:
   - `confirmed` — the defect is present, same mechanism, same consequence.
   - `likely` — same shape, couldn't fully rule the path in or out from reading.
   - `needs-eyes` — structurally similar, genuine doubt, worth a human glance.
   Note blast radius (user-facing? data? a hot path?) where it changes priority.
6. **Present the ranked list and stop.** Lead with `confirmed`. If the sweep found nothing, say
   so plainly and say what you searched for — don't manufacture hits.

## Constraints
- Report only. No edits, no review artifact.
- One pattern per run. If the fix revealed a second unrelated class, note it and run again.
- Don't downgrade "I couldn't tell" to `confirmed` to look decisive, or up to `needs-eyes` to
  look thorough.
- "No siblings" is a valid, useful result — state the searches that produced it.
