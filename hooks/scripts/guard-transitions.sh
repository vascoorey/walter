#!/usr/bin/env bash
# PreToolUse (Bash matcher): deny any `backlog` command that moves a task into a
# human-gated status (default: Done). Exit 2 = block; stderr goes back to the agent.
set -uo pipefail

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -n "$CMD" ] || exit 0

# Best-effort: catch bash-side writes the Write/Edit guard would have blocked
# (redirects, tee, sed -i, mv/cp/rm into task files or rogue plan files).
# String-level, not a shell parser — honest-but-forgetful bar, not adversarial-proof.
if printf '%s' "$CMD" | grep -qiE '(>>?|\btee\b|\bsed\b[^|;&]*-i|\bmv\b|\bcp\b|\brm\b)[^|;&]*backlog/tasks/'; then
  {
    echo "BLOCKED: never write task files via shell — metadata integrity depends on the CLI."
    echo "Use: backlog task edit <id> [-s <status>] [--notes ...] (or backlog task archive)."
  } >&2
  exit 2
fi
if printf '%s' "$CMD" | grep -qiE "(>>?|\btee\b)[[:space:]]*[\"']?([^\"'|;& ]*/)?(todo|plan|tasks|todos)\.md\b"; then
  {
    echo "BLOCKED: the board is the single source of truth. No TODO.md / PLAN.md / TASKS.md."
    echo "Put tasks on the board instead: backlog task create \"...\" --ac \"...\""
  } >&2
  exit 2
fi

# Only care about backlog CLI invocations that set a status.
printf '%s' "$CMD" | grep -q 'backlog' || exit 0
printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])(-s|--status)([[:space:]=])' || exit 0

REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
GATED=$(jq -r '(.human_gated_statuses // ["Done"])[]' "$CONFIG")

while IFS= read -r STATUS; do
  [ -n "$STATUS" ] || continue
  # Match -s Done | -s "Done" | -s 'Done' | --status Done | --status=Done (case-insensitive).
  # Known false positive: the same pattern inside quoted prose (e.g. --notes "... -s Done ...")
  # also blocks — fails safe; the agent can rephrase the note text.
  if printf '%s' "$CMD" | grep -Eiq "(^|[[:space:]])(-s|--status)[[:space:]=]+[\"']?${STATUS}[\"']?"; then
    {
      echo "BLOCKED: '$STATUS' is a human-gated transition. You may not set it."
      echo "Move the task to '$REVIEW_STATUS' instead, with evidence in the task notes:"
      echo "  - which acceptance criteria are met (check them off via the CLI)"
      echo "  - what verification you ran and its result"
      echo "The human moves '$REVIEW_STATUS' -> '$STATUS' after review."
    } >&2
    exit 2
  fi
done <<< "$GATED"

exit 0
