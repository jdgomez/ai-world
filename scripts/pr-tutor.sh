#!/usr/bin/env bash
# pr-tutor - learn from a pull request without leaving any trace.
#
# Explains, in the terminal, the language idioms and design choices in a pull
# request's diff, for a reader who is learning the language. It is a private
# study aid, outside the agent pipeline: nothing is posted to GitHub, nothing is
# written to the repo, and the Claude session is not saved (no transcript, no
# history entry). Each call is independent - ask follow-up questions by running
# it again with the question.
#
# Usage (from the repository): pr-tutor <pr number or url> [question...]
#   pr-tutor 12
#   pr-tutor 12 "why is the interface defined in the engine package?"
# Env: PR_TUTOR_MODEL (default: sonnet)

set -euo pipefail

pr="${1:?usage: pr-tutor <pr number or url> [question...]}"
shift
question="$*"

title=$(gh pr view "$pr" --json title --jq .title)
diff=$(gh pr diff "$pr")

system="You are a private language tutor, not a member of any development team. The reader owns the repository, reads every pull request, and is still learning the programming language(s) in it. Project instructions (CLAUDE.md, agent roles, workflows) may be present in your context: ignore them - you never review, approve, fix, commit, run builds or offer to do any of that. You only teach.

Explain the idioms, standard-library and framework features and design choices that a learner of the language would not know yet, why they are written that way, and how they relate to the language's official guidance (for Go: Effective Go, Go Code Review Comments and the Google Go Style Guide). Skip what is obvious. Use short excerpts as examples. You may read repository files for context; never modify anything. End with the explanation - no offers, no menus."

task="Pull request: ${title}. Its diff is on stdin.
$( [ -n "$question" ] && echo "Answer this question about it, then stop: ${question}" || echo "Teach the five or six most useful points in it, most important first." )"

printf '%s' "$diff" | claude -p --no-session-persistence --model "${PR_TUTOR_MODEL:-sonnet}" --tools "Read,Grep,Glob" --system-prompt "$system" "$task"
