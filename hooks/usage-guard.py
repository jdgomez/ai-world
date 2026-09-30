#!/usr/bin/env python3
"""PreToolUse hook for Herdr flow agents (brain, executor, reviewer).

Gives agents a controlled stop before the account's usage quota runs out.
Reads ${XDG_CACHE_HOME:-~/.cache}/agent-flow/usage.json, which the status line
(~/.claude/statusline.js) keeps up to date, and:
  - at the soft threshold, tells the agent once to wind down (see the
    "Usage soft stop" section of each agent definition);
  - at the hard threshold, also denies tool calls that would start new work,
    while still allowing the ones needed to save state.

Usage (from agent frontmatter): usage-guard.py <role>
Thresholds can be overridden with USAGE_SOFT_PCT / USAGE_HARD_PCT.
"""
import json
import os
import re
import sys
import time
from pathlib import Path

SOFT_PCT = float(os.environ.get("USAGE_SOFT_PCT", 85))
HARD_PCT = float(os.environ.get("USAGE_HARD_PCT", 95))
WINDOW_LABELS = {"five_hour": "5-hour", "seven_day": "weekly", "spend_limit": "spend"}
MARKER_MAX_AGE_S = 8 * 24 * 3600

# Tool calls that start new work, denied per role at the hard threshold.
NEW_WORK_BASH = {
    "brain": r"herdr\s+(agent\s+(prompt|start)|worktree\s+create|workspace\s+create|pane\s+split)\b",
    "reviewer": r"no-mistakes\s+(axi\s+)?run\b",
}
NEW_WORK_TOOLS = {"executor": {"Skill"}, "reviewer": {"Skill"}}


def worst_window(rate_limits, now):
    """Return (key, pct, resets_at) of the most consumed window still open."""
    worst = None
    for key, window in rate_limits.items():
        if not isinstance(window, dict):
            continue
        pct, resets_at = window.get("used_percentage"), window.get("resets_at")
        if not isinstance(pct, (int, float)):
            continue
        if isinstance(resets_at, (int, float)) and resets_at <= now:
            continue
        if worst is None or pct > worst[1]:
            worst = (key, pct, resets_at)
    return worst


def first_time(marker):
    """True the first time this marker is seen; prunes stale markers."""
    if marker.exists():
        return False
    marker.parent.mkdir(parents=True, exist_ok=True)
    cutoff = time.time() - MARKER_MAX_AGE_S
    for old in marker.parent.iterdir():
        if old.stat().st_mtime < cutoff:
            old.unlink(missing_ok=True)
    marker.touch()
    return True


def main():
    role = sys.argv[1] if len(sys.argv) > 1 else ""
    cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "agent-flow"
    usage = json.loads((cache / "usage.json").read_text())
    event = json.load(sys.stdin)

    now = time.time()
    worst = worst_window(usage.get("rate_limits") or {}, now)
    if worst is None or worst[1] < SOFT_PCT:
        return
    key, pct, resets_at = worst
    level = "hard" if pct >= HARD_PCT else "soft"
    label = WINDOW_LABELS.get(key, key)
    resets = time.strftime("%Y-%m-%d %H:%M", time.localtime(resets_at)) if resets_at else "unknown"
    status = f"Usage limit: {pct:.0f}% of the {label} quota is used (resets {resets})."

    output = {"hookEventName": "PreToolUse"}

    if level == "hard":
        tool = event.get("tool_name", "")
        command = (event.get("tool_input") or {}).get("command", "")
        bash_pattern = NEW_WORK_BASH.get(role)
        starts_new_work = tool in NEW_WORK_TOOLS.get(role, ()) or (
            tool == "Bash" and bash_pattern and re.search(bash_pattern, command)
        )
        if starts_new_work:
            output["permissionDecision"] = "deny"
            output["permissionDecisionReason"] = (
                f"{status} Hard stop: no new work may start. Save your state and end your turn "
                'as described in the "Usage soft stop" section of your instructions.'
            )

    marker = cache / "usage-notified" / f"{event.get('session_id', 'unknown')}.{level}.{key}.{int(resets_at or 0)}"
    if first_time(marker):
        urgency = (
            "Stop now: save your state and end your turn."
            if level == "hard"
            else "Start winding down: bring the current step to a safe point, save your state and end your turn."
        )
        output["additionalContext"] = (
            f'{status} {urgency} Follow the "Usage soft stop" section of your instructions. '
            f"Do not start new work until the quota resets at {resets}."
        )

    if len(output) > 1:
        print(json.dumps({"hookSpecificOutput": output}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Never let the guard break a tool call (missing file, bad JSON, ...).
        pass
    sys.exit(0)
