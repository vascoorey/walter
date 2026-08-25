#!/usr/bin/env bash
# BD-19 end-to-end: hooks must not advertise a column the repo's board doesn't have.
# Three boards (full / no-Pairing / minimal v0.1) plus the unknown-list fail-open case.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOT=${WALTER_TEST_ROOT:-$(mktemp -d)}
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
has(){ case "$1" in *"$2"*) ok yes yes "$3";; *) ok no yes "$3 | missing [$2]";; esac; }
hasnt(){ case "$1" in *"$2"*) ok yes no "$3 | unexpected [$2]";; *) ok no no "$3";; esac; }

mkboard(){ # $1=dir $2=statuses-line
  local D="$ROOT/$1"
  rm -rf "$D"; mkdir -p "$D"; cd "$D" || exit 1
  git init -q . && git commit -q --allow-empty -m init
  backlog init "$1" --agent-instructions none --check-branches false --include-remote false >/dev/null 2>&1
  sed -i '' "s/^statuses: .*/statuses: [$2]/" backlog/config.yml
  mkdir -p .board backlog/decisions
  cat > .board/config.json <<'EOF'
{ "test_command": "true", "review_status": "Review", "human_gated_statuses": ["Done"],
  "triage_status": "Triage", "blocked_status": "Blocked", "human_attention_status": "Needs Attention",
  "decisions_dir": "backlog/decisions", "dod_baseline": [] }
EOF
  backlog task create "the work" >/dev/null 2>&1
  backlog task edit task-1 --status "In Progress" >/dev/null 2>&1
}
ss(){ echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1; }
sg(){ jq -nc --arg s "$1" '{session_id:$s,stop_hook_active:false}' | bash "$PLUGIN/hooks/scripts/stop-gate.sh" 2>&1; }

echo "== board A: every column present (regression) =="
mkboard bd19-full '"Triage", "To Do", "In Progress", "Pairing", "Blocked", "Needs Attention", "Review", "Done"'
A=$(ss); AS=$(sg bd19-a)
has "$A" "'Pairing' is human-only" "footer teaches Pairing"
has "$A" "counting In Progress and 'Pairing' together" "focus rule counts both columns"
has "$A" "'Blocked' (external impediment)" "land-the-plane lists Blocked"
has "$A" "'Needs Attention' (ball in the human's court)" "land-the-plane lists the human column"
has "$AS" "recommend 'Pairing'" "stop-gate teaches the Pairing recommendation"
has "$AS" "move to 'Blocked'" "stop-gate offers Blocked"
has "$AS" "move to 'Needs Attention'" "stop-gate offers the human column"
has "$AS" "'Needs Attention' is always legal" "closer names the human column"
has "$AS" "4. Unfinished remainder" "four options when all columns exist"

echo
echo "== board B: no Pairing column (the ShannonAndTheRiots case) =="
mkboard bd19-nopair '"Triage", "To Do", "In Progress", "Blocked", "Needs Attention", "Review", "Done"'
B=$(ss); BS=$(sg bd19-b)
hasnt "$B" "Pairing" "session-start never mentions the absent column"
has "$B" "ONE active commitment at a time: one task, or a parent task with its subtasks. Status updates" "focus rule drops the Pairing clause"
has "$B" "'Blocked' (external impediment)" "columns that DO exist survive"
hasnt "$BS" "Pairing" "stop-gate block never mentions the absent column"
has "$BS" "Land the plane before stopping" "stop-gate still blocks"
has "$BS" "move to 'Needs Attention'" "human column still offered"
has "$BS" "4. Unfinished remainder" "still four options"

echo
echo "== board C: minimal v0.1 board, no parked columns at all =="
mkboard bd19-min '"Triage", "To Do", "In Progress", "Review", "Done"'
C=$(ss); CS=$(sg bd19-c)
hasnt "$C" "Pairing" "no Pairing"
hasnt "$C" "external impediment" "no Blocked guidance"
hasnt "$C" "ball in the human's court" "no human-column guidance"
has "$C" "Land the plane: 'Review' with evidence, or a follow-up task" "land-the-plane degrades to what exists"
hasnt "$CS" "move to 'Blocked'" "stop-gate does not offer Blocked"
hasnt "$CS" "move to 'Needs Attention'" "stop-gate does not offer the human column"
has "$CS" "2. Unfinished remainder" "options renumber to two"
has "$CS" "Pick the honest one. Then stop." "closer drops the always-legal claim"
hasnt "$CS" "option 3" "no dangling option number"

echo
echo "== board D: status list unreadable -> fail open, keep every mention =="
D="$ROOT/bd19-unknown"; rm -rf "$D"; mkdir -p "$D/.board"; cd "$D" || exit 1
cat > .board/config.json <<'EOF'
{ "test_command": "true", "review_status": "Review", "human_gated_statuses": ["Done"],
  "triage_status": "Triage", "blocked_status": "Blocked", "human_attention_status": "Needs Attention",
  "decisions_dir": "backlog/decisions", "dod_baseline": [] }
EOF
DD=$(ss)
has "$DD" "'Pairing' is human-only" "unknown list keeps the Pairing rule"
has "$DD" "'Blocked' (external impediment)" "unknown list keeps Blocked"
( . "$PLUGIN/hooks/scripts/lib/board.sh"
  board_has_status "Anything At All" && echo YES || echo NO ) > "$ROOT/.bd19probe"
ok "$(cat "$ROOT/.bd19probe")" "YES" "board_has_status defaults to present when the list is empty"

echo
echo "== exact matching, not substring =="
cd "$ROOT/bd19-full" || exit 1
( . "$PLUGIN/hooks/scripts/lib/board.sh"
  board_has_status "Review" && echo -n "1"; board_has_status "In Review" || echo -n "0"
  board_has_status "in progress" && echo -n "1"; echo ) > "$ROOT/.bd19probe2"
ok "$(cat "$ROOT/.bd19probe2")" "101" "exact line match, case-insensitive, no substring hits"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
rm -f /tmp/walter-stop-bd19-* "$ROOT/.bd19probe" "$ROOT/.bd19probe2"
[ "$FAIL" -eq 0 ]
