#!/usr/bin/env bash
# PreToolUse (Bash matcher): deny any board-tool command that moves a task into a
# human-gated status (default: Done). Exit 2 = block; stderr goes back to the agent.
# Runs on EVERY Bash tool call — keep it to local string matching, no I/O.
set -uo pipefail

# All board-tool knowledge lives in lib/board.sh. A missing lib means a broken
# install, not a broken user environment: fail open rather than break the session.
. "$(dirname "${BASH_SOURCE[0]}")/lib/board.sh" 2>/dev/null || exit 0

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -n "$CMD" ] || exit 0

# Best-effort: catch bash-side writes the Write/Edit guard would have blocked.
if board_cmd_writes_task_file "$CMD"; then
  {
    echo "BLOCKED: never write task files via shell — metadata integrity depends on the CLI."
    echo "Use: $(board_mutate_hint)"
  } >&2
  exit 2
fi
if printf '%s' "$CMD" | grep -qiE "(>>?|\btee\b)[[:space:]]*[\"']?([^\"'|;& ]*/)?(todo|plan|tasks|todos)\.md\b"; then
  {
    echo "BLOCKED: the board is the single source of truth. No TODO.md / PLAN.md / TASKS.md."
    echo "Put tasks on the board instead: $(board_create_hint)"
  } >&2
  exit 2
fi

# Only care about board-tool invocations that set a status.
board_cmd_touches_status "$CMD" || exit 0

REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
GATED=$(jq -r '(.human_gated_statuses // ["Done"])[]' "$CONFIG")

while IFS= read -r STATUS; do
  [ -n "$STATUS" ] || continue
  if board_cmd_sets_status "$CMD" "$STATUS"; then
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
