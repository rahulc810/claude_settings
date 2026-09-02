---
mode: agent
description: 'Take raw idea notes and adversarially decide whether each should become a prompt file — fold, add, or drop — with an in-principle rating.'
tools: ['codebase', 'search', 'editFiles']
---
# Forge

Input: `${input:input:dir to scan (default docs/prompt-ideas/), or prose describing a revision to an existing prompt}`.

Turns raw ideas into prompt-file decisions. For each idea it models the strongest version of
the prompt implied, runs an internal Proposer/Skeptic debate, and renders a verdict plus a
rating.

> Ported from a Claude Code skill. "skill" == a `.github/prompts/*.prompt.md` file here;
> the registry is that directory. Adjust paths to your repo's convention.

## When to use this
- `docs/prompt-ideas/` has accumulated candidates and you want them triaged.
- **Revision mode** — a prose argument (not a scan dir) naming a change to what an existing
  prompt *does*: its procedure, triggers, tools, or a mis-calibration. No new idea file needed.
- Skip only for a pure wording fix — just make it.

## Procedure
1. **Resolve the input.** If the argument is prose describing a change to an existing prompt,
   this is **revision mode**: skip the scan, model the target prompt as it stands and the
   proposed change, run steps 2-4 on *the change*, write the report section, and on confirm
   apply the edit directly. Otherwise scan the argument dir (else `docs/prompt-ideas/`) for
   `*.md` and process each in order.
2. **Proposer pass** — model the strongest prompt the idea implies: name, one-line purpose,
   trigger phrases, the procedure it would run, the artifact or outcome it produces, the
   recurring need it serves. Steelman it. Write this case into the report before the Skeptic
   pass.
3. **Skeptic pass** — assume the prompt should *not* exist; make the idea earn its place.
   Attack on four axes:
   - **Overlap** — against every existing `.github/prompts/*.prompt.md`. Name any prompt it
     duplicates or heavily shares discipline with.
   - **Realness** — is the need recurring or a one-off? Cite evidence.
   - **Prompt-shaped** — is this a reusable *procedure*, or a preference / fact / one-time task
     that belongs in `copilot-instructions.md`?
   - **Context cost** — does an always-visible `description` for this pay for itself?
4. **Synthesis** — reconcile the two passes, citing named Proposer and Skeptic points (a named
   overlap must be addressed). Apply the rule:
   - Distinctness <= 2 -> **fold into `<existing>`** — unless Recurrence >= 4 *and* folding
     would push the host past ~120 lines, then **add**.
   - Prompt-fit <= 2 **or** Recurrence <= 2 -> **drop** (say which axis, and where the content
     should go instead).
   - Otherwise -> **add as new**.
5. **Rating, in principle** — score independent of the verdict. Five axes, 1-5, one line of
   justification each:

   | Axis | 1 | 5 |
   |---|---|---|
   | Recurrence | seen once | arises weekly |
   | Distinctness | ~duplicate | no neighbour |
   | Prompt-fit | belongs in instructions | clearly a repeatable procedure |
   | Scope tightness | vague / broad | single crisp trigger->outcome |
   | Context cost | heavy for niche value | cheap or high-value |
6. **Write the report** to `docs/prompt-ideas/_assessments/<YYYY-MM-DD>.md` — one file per run,
   each idea a section: modeled prompt, Proposer case, Skeptic case, verdict, rating.
7. **Act on confirm, per item:**
   - **add** — write `.github/prompts/<name>.prompt.md` to the authoring standard.
   - **fold** — show the exact edit (target prompt, section, added text); apply on yes.
   - **drop** — record the reason.
   Then move every processed idea file to `docs/prompt-ideas/_processed/` with the verdict
   appended. Never delete an idea file.

## Constraints
- Proposer's full case is written to the report before the Skeptic pass begins.
- The Skeptic argues from "this should not exist"; a weak defence is a finding, not a pass.
- Synthesis must address every overlap the Skeptic named.
- `add` produces a first draft; a real design pass is `/designit`.
