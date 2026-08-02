---
name: resume
description: Resume from a handoff brief on the mcp-brief server. Use at the start of a session to continue prior work from Claude web or Claude Code.
disable-model-invocation: true
allowed-tools: mcp__brief-local__get_brief, mcp__brief-local__list_briefs, mcp__brief-local__send_brief, mcp__brief-local__complete_brief
---
Continue prior work from a handoff brief on the mcp-brief MCP server.

List the available briefs. If the user named or described one, pick that; otherwise take the most recent. If none exist, say so and stop.

Read the chosen brief in full. Then:
- Follow its "suggested skills" section — invoke those skills as needed.
- Resolve any references it points to (paths, URLs, commits) before acting.
- Continue from the stated next step. Don't redo settled decisions it records.

Briefly confirm what you're picking up and the next action before proceeding, so the user can redirect if it's the wrong brief.