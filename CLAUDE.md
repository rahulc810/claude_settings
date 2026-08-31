- Batch independent tool calls into one message. Separate messages only when
  call N+1 needs call N's result. Each extra round-trip resends the whole
  conversation: a ~84K cache read (~10% of input price), a fresh cache write
  for the new turn, and a latency hop. The volume is 84K; the bill is a tenth
  of that — latency and context bloat are the real costs, not the tokens.
- Default to one script, not a probe. For recon, write a single Bash call with
  `echo "=== label"` section headers rather than one command per question —
  the batching failure is almost always a run of independent probes, not a
  genuine dependency. Repo recon is one call: `git -C <r> status --short`
  + `log --oneline -3` + `remote -v` + `status -sb`.
- Use absolute paths in Bash. Never prefix with `cd` — it triggers
  permission prompts.
- Reading and searching: bash (`grep`, `find`, `cat`, `sed -n`, pipes) is
  preferred — chain steps in one call, filter before output enters context.
  Read is for images, PDFs, and notebooks, which bash cannot handle.
- Writing, low stakes: bash (`sed -i`, heredoc, append) for appending to a
  doc, rewriting a file you just authored, scratch files.
- Writing, surgical: use Edit for changes to code or config, where a pattern
  matching more places than intended would be expensive and silent. Edit fails
  loudly on an ambiguous or missing match; `sed -i` fails quietly. This
  overrides auto mode's "make file changes with sed, heredocs, or short
  scripts" for this case only.
- Read a file before editing it.


## Communication style

When reporting information to me, be extremely concise and sacrifice grammar for sake of concision.
~~use ASD-STE-100 for status updates and instructions; for uncertainty, trade-offs, or explanations of why, you may use full sentences and hedging language.~~


---

# Standing instructions

These apply to every session and every subagent, in every repo.

## Paths and shell

- The code tree is `/storage1/Documents/code`. It is also reachable as
  `/home/rahul/Documents/code` — the same files. Pick the `/storage1` form and
  never mix the two in one task; mixing breaks editor links and file identity.
- Run git as `git -C <repo> …`. Never rely on a `cd` persisting between Bash
  calls — it does not survive a tool-use rejection or interruption.
- After any interruption or rejected tool call, re-verify the working directory
  before the next repo-relative command. Prefer absolute paths so it does not
  matter.
- Before editing in a repo, run `git status --short`. A dirty or mixed tree is
  the user's call on commit strategy — surface it, do not commit through it.

## Reporting

- Lead with the verdict: PASS/FAIL, breaks/safe, found/not-found.
- Name what you actually searched or ran — the patterns, the commands. "No
  impact" with no stated search is not a finding.
- State what you could not verify: a missing venv, a repo you lacked access to,
  a check you skipped. Never report success for a check you did not run.
- Do not soften a breaking result into a caveat. If it breaks, say so first.

## Safety limits

- A task scoped as read-only, or "just tell me / what breaks / diagnose" — make
  no edits.
- No long-lived server in the foreground. Use `timeout N` or the systemd unit,
  and report what you started and whether you stopped it.
- Never blanket `pkill python` / `pkill -f uvicorn`. Find the owning PID with
  `ss -ltnp` first. Several projects in this tree run servers.
- systemd here is user units: always `--user`.
- Never write to `~/databases`. Point tests at `{PREFIX}_DB_DIR=$(mktemp -d)`.
- A multi-line shell snippet handed to the user is a deliverable — reason
  through each line (which host, which privilege, does the redirect apply where
  you think) before sending.

## Evidence discipline

- A derived result that comes back uniform (all-absent, all-zero, all-null) is a
  failing parser until proven otherwise, not a finding. Sanity-check the
  intermediate.
- Before blaming a config for being absent or wrong, read that config. Absence
  of an effect is not absence of a cause.
- A grep count is not an impact analysis. Read each hit — positional vs keyword
  arguments break differently.
- For a UI bug with client-side persisted state (localStorage, cookies, cached
  DOM class), check that state alongside the build pipeline. A correct-looking
  fix that changes nothing visible is a cue to look at what selects the rendered
  branch.

## Where information goes

Five stores. Put each fact in exactly one; cross-reference if it spans two.

| Store | Put here | Do not put here |
|---|---|---|
| **brief** (`brief-local`) | Session continuity only: ending a session with work in flight, or the user says "handoff" / "pause". Include done / next / open questions / key paths. Read via `get_brief` when the user flags a session as a continuation, or on `/resume`. A brief is consumed and `complete_brief`d. | Anything meant to outlive the next session. |
| **erp tasker** (`erp-local`) | **Tasks: any domain.** `create_task` for every concrete follow-up that will not be done this session — a deferred fix, a discovered bug, a chore pushed to later — whatever repo or subject it came from. A todo left in prose only is a todo lost; if it is worth saying "later", it is worth a row. **Notes: the home-infra domain** (erp, vacbat/solar, deebot, network, dnsmasq, HVAC) — `create_note` / `append_to_note` for a small project-scoped fact: a config value, a live-box gotcha, a decision. `add_comment` to reply on an existing thread. Check `get_upcoming` / `list_tasks` at the start of home-infra work. | Steps you are about to do now. Long-form reference — that is wiki. |
| **wiki** (`wiki-local`) | Durable domain knowledge a future session would waste time rediscovering: how a system works, why a design was chosen, a runbook, a non-obvious relationship. `write_doc` / `append_to_doc` for prose, `create_entity` for a system/host/service that needs a stable identity. `search` the wiki before starting non-trivial work on a system. **Propose the write at the moment the fact is established** — name the title and the gist in one line and get an explicit yes before writing. Never write silently, and do not batch the proposal to session end. | Transient state, tasks, session logs, half-formed notes. |
| **file memory** (`~/.claude/projects/*/memory/`) | How to work with this user: preferences, corrections, standing guidance, project context not in the code. See the memory instructions in the system prompt. | Domain facts about the systems — that is wiki. |
| **`docs/notice.md`** (this repo) | Recurring skill friction, workarounds, "I always do it this way" moments — raw material for a future skill change. | Anything actionable now. |

Tie-breakers:

- Actionable and deferred → erp task. Not actionable but durable → wiki doc
  (domain) or erp note (small). Consumed next session → brief. About the user →
  file memory. About a skill → `notice.md`.
- If it is both a task and a reference, make the erp task and the wiki doc, and
  link each to the other.
- Getting information back *out* is `/resume` — it sweeps all four stores,
  dedupes and ranks. It is explicitly invoked, not automatic: the sweep costs a
  round-trip per store, so it does not run on every session. Offer it in one
  line when the user opens on a system with known history, or gives a
  continuation cue ("continue", "pick up", "what did we do about X"), and let
  them say yes or wave it off.
- Use the `*-local` servers. The `claude_ai_*` entries are the same tools over
  the hosted connector — only reach for them if the local one is down.
- `wiki-local` may be failing to connect. If so, report that so it can be
  fixed or retried — do not silently fall back to writing the knowledge
  nowhere.
