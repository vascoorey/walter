#!/usr/bin/env bash
# PreToolUse (Write|Edit matcher): two protections for board integrity.
# 1. Task files must be mutated via the backlog CLI, never edited directly
#    (direct edits corrupt metadata and bypass the transition guard).
# 2. No rogue state files (TODO.md / PLAN.md / TASKS.md) — the board is the
#    single source of truth; parallel plan files drift and lie.
set -uo pipefail

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -n "$FILE" ] || exit 0

if printf '%s' "$FILE" | grep -Eq '(^|/)backlog/tasks/[^/]+\.md$'; then
  {
    echo "BLOCKED: never edit task files directly — metadata integrity depends on the CLI."
    echo "Use: backlog task edit <id> [-s <status>] [--notes ...] [--ac ...] etc."
  } >&2
  exit 2
fi

BASENAME=$(basename "$FILE" | tr '[:lower:]' '[:upper:]')
case "$BASENAME" in
  TODO.MD|PLAN.MD|TASKS.MD|TODOS.MD)
    {
      echo "BLOCKED: the board is the single source of truth for intent and state."
      echo "Do not create parallel plan/state files. Put tasks on the board:"
      echo "  backlog task create \"...\" --ac \"...\""
    } >&2
    exit 2
    ;;
esac

exit 0
