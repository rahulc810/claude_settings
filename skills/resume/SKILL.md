---
name: resume
description: Search the four stores — briefs, erp tasks, erp notes, wiki — for prior context on a topic, then pick up a thread or start fresh. Trigger on:- resume, continue prior work, what do we know about, any prior work on, pick up where we left off.
disable-model-invocation: true
argument-hint: "[topic or system; omit to take the most recent brief]"
allowed-tools: mcp__brief-local__list_briefs, mcp__brief-local__get_brief, mcp__brief-local__send_brief, mcp__brief-local__complete_brief, mcp__erp-local__list_tasks, mcp__erp-local__get_task, mcp__erp-local__list_notes, mcp__erp-local__get_note, mcp__erp-local__get_upcoming, mcp__wiki-local__search, mcp__wiki-local__get_doc, mcp__wiki-local__get_entity
model: claude-sonnet-5
---

Orient a session against everything already known about a topic, before doing work that
may re-derive it.

## When to use this

- Starting substantive work on a system that has history — invoked explicitly, since the
  four-store sweep costs a round-trip each.
- Continuing from a handoff brief (the original use; still the default with no argument).
- Skip for a self-contained one-off, or a topic that plainly has no prior work.

## Procedure

1. **Derive terms** — from the argument, or from the user's opening request, take 2–3
   search terms: the system or host name, the component, the problem word. Include the
   obvious synonym — the stores match literally, so `dnsmasq` and `DHCP` are two terms,
   not one. With no argument and no topic, skip to step 2 and take the most recent brief.

2. **Sweep the four stores** — one pass each, batched in a single message:
   - `list_briefs` — in-flight session continuity.
   - `list_tasks` (plus `get_upcoming` when the topic is home-infra) — open follow-ups.
   - `list_notes` — small project-scoped facts.
   - `wiki-local` `search` — durable domain knowledge.
   If `wiki-local` fails to connect, say so in the shortlist rather than silently
   returning a wiki-less result.

3. **Dedupe and rank** — the same fact often sits in two stores (a task linked to a wiki
   doc). Collapse those into one row. Rank by closeness to the terms first, recency
   second.

4. **Present a shortlist** — at most 5–7 rows, numbered: store, title, date, one line of
   gist. Then stop and ask: pick a row, or start fresh.

5. **Branch:**
   - **Pick** — read that item in full (`get_brief` / `get_task` / `get_note` /
     `get_doc`). Resolve the references it names (paths, URLs, commits) before acting.
     Continue from its stated next step; don't redo decisions it records. For a brief,
     follow its "suggested skills" section.
   - **Nothing found, or fresh** — say so in one line and start the work clean. An empty
     sweep is a valid outcome, not a dead end.

6. **Confirm before proceeding** — one line on what you're picking up and the next
   action, so the user can redirect if it's the wrong thread.

## Constraints

- Read-only across all four stores. The one exception: a brief that was picked up and
  finished is `complete_brief`d, as before.
- Never act on a shortlist row without the user picking it — present, then wait.
- Don't widen a found thread's scope. It says what it says; new work is new work.
- No fabricated gist. If a row's content wasn't read, the gist is its title.

## Done criteria

- All four stores swept (or the failure of one reported), results deduped and ranked.
- A shortlist presented and a thread picked, or "nothing relevant / starting fresh"
  stated explicitly.
- The next action confirmed in one line before work begins.
