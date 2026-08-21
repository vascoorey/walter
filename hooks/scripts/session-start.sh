#!/usr/bin/env bash
# SessionStart: stdout becomes agent context.
# Injects: board summary (one line per task), any In Progress task in full,
# and recently-touched decision docs. Fail-open: if repo isn't onboarded, stay silent.
set -uo pipefail

# All board-tool knowledge lives in lib/board.sh. A missing lib means a broken
# install, not a broken user environment: fail open rather than break the session.
. "$(dirname "${BASH_SOURCE[0]}")/lib/board.sh" 2>/dev/null || exit 0

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
board_available || { echo "[board] $BOARD_TOOL CLI not found — board state unavailable this session."; exit 0; }
command -v jq >/dev/null 2>&1 || exit 0

REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
TRIAGE_STATUS=$(jq -r '.triage_status // "Triage"' "$CONFIG")
BLOCKED_STATUS=$(jq -r '.blocked_status // "Blocked"' "$CONFIG")
HUMAN_STATUS=$(jq -r '.human_attention_status // "Needs Attention"' "$CONFIG")
PAIRING_STATUS=$(jq -r '.pairing_status // "Pairing"' "$CONFIG")
DECISIONS_DIR=$(jq -r '.decisions_dir // "backlog/decisions"' "$CONFIG")

echo "## Board state (source of truth — keep it accurate in real time)"
echo ""

board_summary || echo "(could not read board)"
echo ""

# Active work, in full detail. Two columns are active: In Progress (agent executing,
# never survives a stop) and the pairing column (an open thread with the human that
# deliberately does survive one — human-only entry, so the agent can't park work there).
IN_PROGRESS=$(board_ids_in_status "In Progress")
PAIRING=$(board_ids_in_status "$PAIRING_STATUS")
if [ -n "$IN_PROGRESS" ]; then
  echo "### In Progress (your current focus — finish these before pulling new work)"
  for T in $IN_PROGRESS; do
    board_show "$T"
    echo "---"
  done
  echo ""
fi
if [ -n "$PAIRING" ]; then
  echo "### $PAIRING_STATUS (open thread with the human — active work that survives a stop)"
  for T in $PAIRING; do
    board_show "$T"
    echo "---"
  done
  echo "Keep working these, code included, WITHOUT moving them to In Progress. Only the human puts a task here; you may move one out ('$REVIEW_STATUS', '$BLOCKED_STATUS', '$HUMAN_STATUS') once the thread concludes."
  echo ""
fi
if [ -z "$IN_PROGRESS" ] && [ -z "$PAIRING" ]; then
  echo "No task is active. Pull ONE task from To Do, set it In Progress before touching code."
  echo ""
fi

# Parked tasks: the handoff round-trip. In Progress means actively executing;
# these columns hold work that stopped honestly. Resuming one REQUIRES moving it back.
HUMAN_PARKED=$(board_lines_in_status "$HUMAN_STATUS")
if [ -n "$HUMAN_PARKED" ]; then
  echo "### $HUMAN_STATUS (waiting on the human — read the task notes for what was asked)"
  echo "$HUMAN_PARKED"
  echo "If the human has answered and you are resuming one: move it back to In Progress via the CLI BEFORE touching code."
  echo ""
fi
BLOCKED_PARKED=$(board_lines_in_status "$BLOCKED_STATUS")
if [ -n "$BLOCKED_PARKED" ]; then
  echo "### $BLOCKED_STATUS (external impediments — notes name each blocker)"
  echo "$BLOCKED_PARKED"
  echo "Only resume one if its blocker is actually cleared; then move it back to In Progress first."
  echo ""
fi

# Recent decisions = shared context across streams.
if [ -d "$DECISIONS_DIR" ]; then
  RECENT=$(ls -t "$DECISIONS_DIR" 2>/dev/null | head -5)
  if [ -n "$RECENT" ]; then
    echo "### Recent decisions (binding context — do not contradict without a new decision doc)"
    echo "$RECENT" | sed "s|^|- $DECISIONS_DIR/|"
    echo "Read any decision doc relevant to your task before starting."
  fi
fi
echo ""

echo "### Board rules (enforced by hooks — violations will be blocked)"
echo "- ONE active task at a time, counting In Progress and '$PAIRING_STATUS' together. Status updates happen in real time, not batched."
echo "- In Progress means actively executing. Stopping? Land the plane: '$REVIEW_STATUS' with evidence, '$BLOCKED_STATUS' (external impediment), '$HUMAN_STATUS' (ball in the human's court), or a follow-up task."
echo "- '$PAIRING_STATUS' is human-only. If a task is turning into multi-turn work with the human, recommend it (note it on the task and say so) — you may not set it yourself."
echo "- '$REVIEW_STATUS' is the most you can set. 'Done' is human-only."
echo "- Discovered work (bugs, refactors, missing deps): create a new task in '$TRIAGE_STATUS', link it, stay on your current task."
echo "- Never edit task files directly. Use: $(board_mutate_hint)"
exit 0
