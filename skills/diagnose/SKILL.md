---
name: diagnose
description: Debugging discipline for measurable systems. Use when asked to diagnose or find the cause of a failure.
model: claude-opus-5
argument-hint: "target: local | server (default: local)"
allowed-tools: Read, Grep, Glob, Bash
---

# Diagnose

Before concluding a cause: get direct evidence for it (a log line, an independent repro, a timestamp), not just a story that fits. If symptoms don't unify under one cause, don't force them to — split and treat separately. Hold conclusions loosely enough to revisit if new evidence contradicts them, even ones already "ruled out."

## Target

- `local` (default) — investigate on this machine directly.
- `server` — investigate over SSH. Follow `~/Documents/code/devkit/.claude/policies/ssh-policy.md`: read-only investigation
  only; any fix or change found along the way needs separate confirmation and is out of
  scope for this skill.

If the argument is omitted and it's ambiguous where the evidence lives (e.g. "the app is
slow" could be either), ask once before proceeding rather than guessing.