---
mode: agent
description: 'Evidence-based debugging discipline for measurable systems. Get direct evidence before concluding a cause.'
tools: ['codebase', 'search', 'runCommands', 'changes', 'problems']
---
# Diagnose

Optional arg (`${input:target:local | ssh}`, default `local`): `local` = investigate on this
machine; `ssh` = investigate over SSH, read-only, any fix found is out of scope and needs
separate confirmation. If it is ambiguous where the evidence lives, ask once before proceeding.

A stance to hold whenever something breaks, not a pipeline stage. Fixes found here are out of
scope — hand them to `/plan-doc` or `/implement`.

Before concluding a cause: get direct evidence for it (a log line, an independent repro, a
timestamp), not just a story that fits. If symptoms don't unify under one cause, don't force
them to — split and treat separately. Hold conclusions loosely enough to revisit if new
evidence contradicts them, even ones already "ruled out".
