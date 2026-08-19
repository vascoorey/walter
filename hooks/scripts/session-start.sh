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
DECISIONS_DIR=$(jq -r '.decisions_dir // "backlog/decisions"' "$CONFIG")

echo "## Board state (source of truth — keep it accurate in real time)"
echo ""

# Full board, one line per task. --plain keeps it terminal/agent friendly.
backlog board --plain 2>/dev/null || backlog task list --plain 2>/dev/null || echo "(could not read board)"
echo ""

# Surface any task already claimed as In Progress in full detail.
IN_PROGRESS=$(backlog task list --plain -s "In Progress" 2>/dev/null | grep -iEo 'task-[0-9]+(\.[0-9]+)?' | sort -uf)
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
echo "- '$REVIEW_STATUS' is the most you can set. 'Done' is human-only."
echo "- Discovered work (bugs, refactors, missing deps): create a new task in '$TRIAGE_STATUS', link it, stay on your current task."
echo "- Never edit backlog/tasks/*.md directly — use the backlog CLI."
exit 0
