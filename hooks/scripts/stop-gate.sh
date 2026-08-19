#!/usr/bin/env bash
# Stop: the agent may not finish with a red verification gate or an unreconciled board.
# Emits {"decision":"block","reason":...} to force continuation.
# Loop safety: hard cap of 3 blocks per session (counter keyed by session_id),
# and the soft "land the plane" check only fires on the first stop attempt.
set -uo pipefail

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')

COUNTER_FILE="/tmp/board-discipline-stop-${SESSION_ID}"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
if [ "$COUNT" -ge 3 ]; then
  # Give up blocking to avoid an infinite loop; surface loudly instead.
  echo '{"systemMessage":"board-discipline: stop-gate hit its retry cap (3). Verification may still be failing — check manually."}'
  exit 0
fi

block() {
  echo $((COUNT + 1)) > "$COUNTER_FILE"
  jq -n --arg reason "$1" '{"decision":"block","reason":$reason}'
  exit 0
}

# --- Gate 1: verification command (per-repo, defined at onboarding) ---
TEST_CMD=$(jq -r '.test_command // empty' "$CONFIG")
if [ -n "$TEST_CMD" ]; then
  TEST_OUTPUT=$(bash -c "$TEST_CMD" 2>&1)
  TEST_EXIT=$?
  if [ "$TEST_EXIT" -ne 0 ]; then
    TAIL=$(printf '%s' "$TEST_OUTPUT" | tail -30)
    block "Verification gate is RED — you may not stop. Command: ${TEST_CMD} (exit ${TEST_EXIT}).
Fix the failures, or if they are pre-existing/out of scope, create a task for them in Triage and note it on your current task, then stop again.
Last 30 lines:
${TAIL}"
  fi
fi

# --- Gate 2: land the plane (first stop attempt only) ---
if [ "$STOP_ACTIVE" != "true" ] && command -v backlog >/dev/null 2>&1; then
  REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
  IN_PROGRESS=$(backlog task list --plain -s "In Progress" 2>/dev/null | grep -icE 'task-[0-9]+' || true)
  if [ "${IN_PROGRESS:-0}" -gt 0 ]; then
    block "Land the plane before stopping. ${IN_PROGRESS} task(s) still In Progress. For each one, exactly one of:
1. Finished: check off acceptance criteria via the CLI, add verification evidence to notes, move to '${REVIEW_STATUS}'.
2. Blocked: note what blocks it, set the appropriate status/label.
3. Unfinished remainder: create a follow-up task capturing the remaining work, note it, and move this one to '${REVIEW_STATUS}' or back to To Do.
Then stop."
  fi
fi

rm -f "$COUNTER_FILE"
exit 0
