#!/usr/bin/env bash
# Stop: the agent may not finish with a red verification gate or an unreconciled board.
# Emits {"decision":"block","reason":...} to force continuation.
# Loop safety: hard cap of 3 blocks per session (counter keyed by session_id),
# and the soft "land the plane" check only fires on the first stop attempt.
set -uo pipefail

# All board-tool knowledge lives in lib/board.sh. Sourced without an early exit on
# failure: Gate 1 needs no board tool, so a broken install must not disarm it.
# Gate 2 checks that the lib actually loaded before using it.
. "$(dirname "${BASH_SOURCE[0]}")/lib/board.sh" 2>/dev/null || true

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')

# Hygiene: age out this plugin's /tmp state (stop counters, green stamps) older
# than 7 days — dead sessions and repos otherwise accumulate forever on platforms
# that don't purge /tmp. Aging a live green stamp merely costs one extra test run.
# Trailing slash: /tmp is a symlink on macOS and find won't traverse a symlink start point.
find /tmp/ -maxdepth 1 -name 'walter-*' -type f -mtime +7 -delete 2>/dev/null || true

# Counter is per-session by definition: a resume/compaction that changes session_id
# re-arms a capped gate (fresh count). Deliberate — the cap guards against loops
# within one conversation, not across them.
COUNTER_FILE="/tmp/walter-stop-${SESSION_ID}"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
if [ "$COUNT" -ge 3 ]; then
  # Give up blocking to avoid an infinite loop; surface loudly instead.
  echo '{"systemMessage":"walter: stop-gate hit its retry cap (3). Verification may still be failing — check manually."}'
  exit 0
fi

block() {
  echo $((COUNT + 1)) > "$COUNTER_FILE"
  jq -n --arg reason "$1" '{"decision":"block","reason":$reason}'
  exit 0
}

# --- Gate 1: verification command (per-repo, defined at onboarding) ---
# Skipped when repo content is unchanged since the last green run, so chat-only
# turns don't pay test-suite latency. Content = HEAD + tracked diff + untracked
# file hashes + the test command itself. Known stale-green window: failures from
# non-file state (env, services, flaky tests) won't retrigger until content changes.
content_hash() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  {
    printf '%s\n' "$TEST_CMD"
    git rev-parse HEAD 2>/dev/null
    git diff HEAD 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null | while IFS= read -r F; do
      [ -f "$F" ] && shasum "$F" 2>/dev/null
    done
  } | shasum | cut -d' ' -f1
}

TEST_CMD=$(jq -r '.test_command // empty' "$CONFIG")
if [ -n "$TEST_CMD" ]; then
  # ponytail: green stamps live in /tmp keyed by cwd hash; hygiene is task-5
  STAMP="/tmp/walter-green-$(pwd | shasum | cut -d' ' -f1)"
  HASH=$(content_hash) || HASH=""
  if [ -z "$HASH" ] || [ ! -f "$STAMP" ] || [ "$(cat "$STAMP" 2>/dev/null)" != "$HASH" ]; then
    TEST_OUTPUT=$(bash -c "$TEST_CMD" 2>&1)
    TEST_EXIT=$?
    if [ "$TEST_EXIT" -ne 0 ]; then
      TAIL=$(printf '%s' "$TEST_OUTPUT" | tail -30)
      block "Verification gate is RED — you may not stop. Command: ${TEST_CMD} (exit ${TEST_EXIT}).
Fix the failures, or if they are pre-existing/out of scope, create a task for them in Triage and note it on your current task, then stop again.
Last 30 lines:
${TAIL}"
    fi
    # Stamp AFTER the green run (tests may write artifacts; hash the state the
    # next stop will actually see). Outside git repos HASH is empty: never cache.
    HASH=$(content_hash) || HASH=""
    [ -n "$HASH" ] && echo "$HASH" > "$STAMP"
  fi
fi

# --- Gate 2: land the plane (first stop attempt only) ---
if [ "$STOP_ACTIVE" != "true" ] && command -v board_available >/dev/null 2>&1 && board_available; then
  REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
  BLOCKED_STATUS=$(jq -r '.blocked_status // "Blocked"' "$CONFIG")
  HUMAN_STATUS=$(jq -r '.human_attention_status // "Needs Attention"' "$CONFIG")
  PAIRING_STATUS=$(jq -r '.pairing_status // "Pairing"' "$CONFIG")
  # Only In Progress counts as dangling. The pairing column is active work the human
  # explicitly sanctioned to survive a stop; counting it would recreate the tedium
  # it exists to remove. Human-only entry is what keeps that from being a loophole.
  IN_PROGRESS=$(board_lines_in_status "In Progress" | grep -c . || true)
  if [ "${IN_PROGRESS:-0}" -gt 0 ]; then
    # Offer only exits this board actually has (BD-19). Options are referenced by
    # name, never by number, so a missing column can't leave a dangling "option 3".
    OPTS=""; N=0
    add_opt() { N=$((N + 1)); OPTS="${OPTS}${N}. $1"$'\n'; }
    add_opt "Finished: check off acceptance criteria via the CLI, add verification evidence to notes, move to '${REVIEW_STATUS}'."
    board_has_status "$BLOCKED_STATUS" &&
      add_opt "Blocked on something external: note the impediment, move to '${BLOCKED_STATUS}'."
    HAS_HUMAN=false
    if board_has_status "$HUMAN_STATUS"; then
      HAS_HUMAN=true
      add_opt "Ball in the human's court (question, decision, handoff, mid-conversation pause): note what you need, move to '${HUMAN_STATUS}'. Move it back to In Progress when you resume."
    fi
    add_opt "Unfinished remainder: create a follow-up task capturing the remaining work, note it, and move this one to '${REVIEW_STATUS}' or back to To Do."

    CLOSER="Pick the honest one. Then stop."
    $HAS_HUMAN && CLOSER="Pick the honest one — '${HUMAN_STATUS}' is always legal. Then stop."
    if board_has_status "$PAIRING_STATUS"; then
      PARK="pick one of the options above"
      $HAS_HUMAN && PARK="park it in '${HUMAN_STATUS}'"
      CLOSER="${CLOSER}
If this task has become a genuine back-and-forth with the human rather than execution, recommend '${PAIRING_STATUS}': note that on the task and say so in your reply, then ${PARK} and stop. '${PAIRING_STATUS}' is human-only; you may not set it."
    fi

    block "Land the plane before stopping. ${IN_PROGRESS} task(s) still In Progress — In Progress means actively executing, and you are stopping. For each one, exactly one of:
${OPTS}${CLOSER}"
  fi
fi

rm -f "$COUNTER_FILE"
exit 0
