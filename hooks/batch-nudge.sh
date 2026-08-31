#!/usr/bin/env bash
# Nudges when several consecutive assistant messages each carry a single
# probe-shaped tool call. Fires on PostToolBatch (once per message).
# Counts only Bash/Read/Grep/Glob singletons — a lone Edit/Write is usually
# correct and unavoidable, so it neither trips nor resets the streak.
set -u
THRESHOLD=3
payload=$(cat)

sid=$(printf '%s' "$payload" | jq -r '.session_id // "nosession"' 2>/dev/null) || sid=nosession
n=$(printf '%s' "$payload"   | jq -r '(.tool_calls // []) | length' 2>/dev/null) || n=0
probes=$(printf '%s' "$payload" | jq -r \
  '[(.tool_calls // [])[] | select(.tool_name|IN("Bash","Read","Grep","Glob"))] | length' 2>/dev/null) || probes=0

state="${TMPDIR:-/tmp}/claude-batch-streak-${sid}"
streak=$(cat "$state" 2>/dev/null || echo 0)
case "$streak" in ''|*[!0-9]*) streak=0 ;; esac

if [ "$n" = "1" ] && [ "$probes" = "1" ]; then
  streak=$((streak + 1))
else
  streak=0            # a real batch, or a non-probe call, clears it
fi

if [ "$streak" -ge "$THRESHOLD" ]; then
  echo 0 > "$state"   # reset so it nudges once per run, not every turn
  jq -cn --arg n "$streak" '{
    hookSpecificOutput: {
      hookEventName: "PostToolBatch",
      additionalContext: ("Batching check: the last \($n) messages each made exactly one "
        + "probe call (Bash/Read/Grep/Glob). If the next steps do not depend on each "
        + "other, issue them in ONE message — or fold the shell probes into a single "
        + "Bash call with `echo \"=== label\"` section headers. Ignore this if each call "
        + "genuinely needed the previous result.")
    }
  }'
else
  echo "$streak" > "$state"
  printf '{}\n'
fi
