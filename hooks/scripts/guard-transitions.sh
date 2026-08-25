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

# Subtasks are human-defined (BD-25). Blanket denial rather than "only under your
# own active parent": that check would need a board query on the hot path, and the
# Pairing precedent says a relaxation the agent can reach for becomes the cheapest
# legal exit. Creating a subtask under an unrelated parent is no loss — the triage
# protocol already routes discovered work to a top-level task.
if board_cmd_creates_subtask "$CMD"; then
  TRIAGE_STATUS=$(jq -r '.triage_status // "Triage"' "$CONFIG")
  PARENT_SH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)/scripts/parent.sh
  {
    echo "BLOCKED: subtasks are human-defined. You may not create one."
    echo "The unit of focus is ONE commitment: a single task, or a parent WITH its"
    echo "subtasks. A batch you can extend yourself is a batch you can grow without"
    echo "ever breaking that rule — which is what the triage protocol exists to stop."
    echo "Discovered work goes to '$TRIAGE_STATUS' as a top-level task: $(board_create_hint)"
    echo "To bundle existing tasks, PROPOSE the batch and hand over this command"
    echo "for the human to run (it keeps every id, filename and field intact):"
    echo "  bash $PARENT_SH <parent-id-or-title> <id> <id> ..."
  } >&2
  exit 2
fi

# Only care about board-tool invocations that set a status.
board_cmd_touches_status "$CMD" || exit 0

REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
HUMAN_STATUS=$(jq -r '.human_attention_status // "Needs Attention"' "$CONFIG")
PAIRING_STATUS=$(jq -r '.pairing_status // "Pairing"' "$CONFIG")
GATED=$(jq -r '(.human_gated_statuses // ["Done"])[]' "$CONFIG")

# The pairing column is human-only entry, checked separately from human_gated_statuses:
# that list is the Review -> Done end gate, whose denial text ("move to Review instead")
# would be wrong guidance here. Entry being human-only is what stops the agent parking
# work in a column the stop-gate ignores.
if [ -n "$PAIRING_STATUS" ] && board_cmd_sets_status "$CMD" "$PAIRING_STATUS"; then
  {
    echo "BLOCKED: '$PAIRING_STATUS' is a human-only column. You may not put a task there."
    echo "It exists so a real back-and-forth with the human stays active across stops."
    echo "You may RECOMMEND it: note on the task that the work has become multi-turn"
    echo "collaboration, say so in your reply, then park the task ('$HUMAN_STATUS') and stop."
    echo "The human moves it. Note via: $(board_mutate_hint)"
  } >&2
  exit 2
fi

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
