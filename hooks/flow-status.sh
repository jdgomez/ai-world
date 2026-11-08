#!/usr/bin/env bash
# Stop hook for Herdr flow workers (executor, reviewer).
# Writes the completion line of the turn that just ended to
#   ${XDG_CACHE_HOME:-~/.cache}/agent-flow/<HERDR_WORKSPACE_ID>/<role>.status
# so Brain can read one small file instead of the agent's pane.
# If none of the turn's last five lines is a completion line, it writes "MISSING".
# Also used as a StopFailure hook: a turn killed by an API error (e.g. the
# usage limit) writes "BLOCKED reason=<error type>" instead.
# Usage (from agent frontmatter): flow-status.sh <role>

role="${1:?usage: flow-status.sh <role>}"

# Only meaningful inside a Herdr-managed pane.
[ -n "${HERDR_WORKSPACE_ID:-}" ] || exit 0

dir="${XDG_CACHE_HOME:-$HOME/.cache}/agent-flow/$HERDR_WORKSPACE_ID"
mkdir -p "$dir" || exit 0

line=$(python3 -c '
import json, re, sys
event = json.load(sys.stdin)
if event.get("hook_event_name") == "StopFailure":
    print("BLOCKED reason=" + (event.get("error_type") or "unknown"))
    sys.exit(0)
msg = event.get("last_assistant_message") or ""
lines = [l.strip().strip("`").strip() for l in msg.strip().splitlines() if l.strip().strip("`").strip()]
# The completion line should be the last line, but a model sometimes adds a
# stray sentence after it: take the last completion line among the final five.
found = [l for l in lines[-5:] if re.match(r"(DONE|BLOCKED|PASSED|CHANGES_REQUESTED|ASK_USER)\b", l)]
print(found[-1] if found else "MISSING")
') || line="MISSING"

tmp="$dir/.$role.status.$$"
printf '%s\n' "$line" > "$tmp" && mv -f "$tmp" "$dir/$role.status"
exit 0
