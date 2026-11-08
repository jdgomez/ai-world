#!/usr/bin/env bash
# Red check for a TDD pull request: do the branch's new or changed tests fail
# against the production code of the base branch?
#
# It builds a throwaway worktree at the merge base, copies in only the test
# files the branch added or changed, and runs the project's test command there.
#   RED            the tests fail without the branch's production code (expected)
#   GREEN_ON_BASE  they pass without it: they don't prove the new behavior
#   NO_TEST_CHANGES  the branch adds or changes no test file
# A failure to compile counts as RED, but the reviewer should read the tail:
# a test that fails only because a symbol is missing is weaker evidence than
# one that fails on an assertion.
#
# Usage (from the repo or a worktree of it, on the branch under review):
#   tdd-red-check.sh --base <base-branch> --tests '<ERE for test paths>' --cmd '<test command>'
# Example:
#   tdd-red-check.sh --base origin/main --tests '_test\.go$|/testdata/' --cmd 'make test'

set -uo pipefail

base="" tests="" cmd=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --tests) tests="$2"; shift 2 ;;
    --cmd) cmd="$2"; shift 2 ;;
    *) echo "usage: $0 --base <ref> --tests '<ERE>' --cmd '<test command>'" >&2; exit 2 ;;
  esac
done
[ -n "$base" ] && [ -n "$tests" ] && [ -n "$cmd" ] || { echo "usage: $0 --base <ref> --tests '<ERE>' --cmd '<test command>'" >&2; exit 2; }

head=$(git rev-parse HEAD) || exit 2
mb=$(git merge-base "$base" "$head") || { echo "ERROR cannot find merge base of $base and HEAD"; exit 2; }

mapfile -t files < <(git diff --name-only --diff-filter=AM "$mb" "$head" | grep -E -- "$tests")
if [ ${#files[@]} -eq 0 ]; then
  echo "NO_TEST_CHANGES base=${mb:0:8} head=${head:0:8}"
  exit 0
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/tdd-red-check.XXXXXX")
cleanup() { git worktree remove --force "$tmp" >/dev/null 2>&1 || rm -rf "$tmp"; }
trap cleanup EXIT

git worktree add --detach --quiet "$tmp" "$mb" || { echo "ERROR cannot create worktree"; exit 2; }
git -C "$tmp" checkout --quiet "$head" -- "${files[@]}" || { echo "ERROR cannot copy test files"; exit 2; }

log="$tmp/.tdd-red-check.log"
(cd "$tmp" && bash -c "$cmd") >"$log" 2>&1
status=$?

echo "test files (${#files[@]}): ${files[*]}"
if [ $status -eq 0 ]; then
  echo "GREEN_ON_BASE base=${mb:0:8} head=${head:0:8} - the new tests pass without the branch's production code"
else
  echo "RED base=${mb:0:8} head=${head:0:8} exit=$status - last lines:"
  tail -n 40 "$log"
fi
