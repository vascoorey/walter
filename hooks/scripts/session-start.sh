#!/usr/bin/env bash
# SessionStart: stdout becomes agent context.
# Injects: board summary (one line per task), any In Progress task in full,
# and recently-touched decision docs. Fail-open: if repo isn't onboarded, stay silent.
set -uo pipefail

CONFIG=".board/config.json"
[ -f "$CONFIG" ] || exit 0
command -v backlog >/dev/null 2>&1 || { echo "[board] backlog CLI not found — board state unavailable this session."; exit 0; }
command -v jq >/dev/null 2>&1 || exit 0

REVIEW_STATUS=$(jq -r '.review_status // "Review"' "$CONFIG")
TRIAGE_STATUS=$(jq -r '.triage_status // "Triage"' "$CONFIG")
BLOCKED_STATUS=$(jq -r '.blocked_status // "Blocked"' "$CONFIG")
HUMAN_STATUS=$(jq -r '.human_attention_status // "Needs Attention"' "$CONFIG")
DECISIONS_DIR=$(jq -r '.decisions_dir // "backlog/decisions"' "$CONFIG")

echo "## Board state (source of truth — keep it accurate in real time)"
echo ""

# Full board, one line per task. --plain keeps it terminal/agent friendly.
backlog board --plain 2>/dev/null || backlog task list --plain 2>/dev/null || echo "(could not read board)"
echo ""

# Surface any task already claimed as In Progress in full detail.
# Prefix-agnostic: ids sit at the start of --plain list lines ("  <PREFIX>-<N> - ...").
IN_PROGRESS=$(backlog task list --plain -s "In Progress" 2>/dev/null | grep -oE '^[[:space:]]*[A-Za-z]+-[0-9]+(\.[0-9]+)?' | tr -d ' ' | sort -uf)
if [ -n "$IN_PROGRESS" ]; then
  echo "### In Progress (your current focus — finish these before pulling new work)"
  for T in $IN_PROGRESS; do
    backlog task "$T" --plain 2>/dev/null
    echo "---"
  done
else
  echo "No task is In Progress. Pull ONE task from To Do, set it In Progress before touching code."
fi
echo ""

# Parked tasks: the handoff round-trip. In Progress means actively executing;
# these columns hold work that stopped honestly. Resuming one REQUIRES moving it back.
HUMAN_PARKED=$(backlog task list --plain -s "$HUMAN_STATUS" 2>/dev/null | grep -E '^[[:space:]]*[A-Za-z]+-[0-9]+' || true)
if [ -n "$HUMAN_PARKED" ]; then
  echo "### $HUMAN_STATUS (waiting on the human — read the task notes for what was asked)"
  echo "$HUMAN_PARKED"
  echo "If the human has answered and you are resuming one: move it back to In Progress via the CLI BEFORE touching code."
  echo ""
fi
BLOCKED_PARKED=$(backlog task list --plain -s "$BLOCKED_STATUS" 2>/dev/null | grep -E '^[[:space:]]*[A-Za-z]+-[0-9]+' || true)
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
echo "- One task In Progress at a time. Status updates happen in real time, not batched."
echo "- In Progress means actively executing. Stopping? Land the plane: '$REVIEW_STATUS' with evidence, '$BLOCKED_STATUS' (external impediment), '$HUMAN_STATUS' (ball in the human's court), or a follow-up task."
echo "- '$REVIEW_STATUS' is the most you can set. 'Done' is human-only."
echo "- Discovered work (bugs, refactors, missing deps): create a new task in '$TRIAGE_STATUS', link it, stay on your current task."
echo "- Never edit backlog/tasks/*.md directly — use the backlog CLI."
exit 0
