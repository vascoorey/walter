#!/usr/bin/env bash
# PreToolUse (Write|Edit matcher): two protections for board integrity.
# 1. Task files must be mutated via the board CLI, never edited directly
#    (direct edits corrupt metadata and bypass the transition guard).
# 2. No rogue state files (TODO.md / PLAN.md / TASKS.md) — the board is the
#    single source of truth; parallel plan files drift and lie.
set -uo pipefail

# All board-tool knowledge lives in lib/board.sh. A missing lib means a broken
# install, not a broken user environment: fail open rather than break the session.
. "$(dirname "${BASH_SOURCE[0]}")/lib/board.sh" 2>/dev/null || exit 0

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -n "$FILE" ] || exit 0

if board_path_is_task_file "$FILE"; then
  {
    echo "BLOCKED: never edit task files directly — metadata integrity depends on the CLI."
    echo "Use: $(board_mutate_hint)"
  } >&2
  exit 2
fi

BASENAME=$(basename "$FILE" | tr '[:lower:]' '[:upper:]')
case "$BASENAME" in
  TODO.MD|PLAN.MD|TASKS.MD|TODOS.MD)
    {
      echo "BLOCKED: the board is the single source of truth for intent and state."
      echo "Do not create parallel plan/state files. Put tasks on the board:"
      echo "  $(board_create_hint)"
    } >&2
    exit 2
    ;;
esac

exit 0
