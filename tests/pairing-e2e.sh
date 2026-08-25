#!/usr/bin/env bash
# BD-15 end-to-end: the Pairing column. Human-only entry, survives a stop,
# surfaced as active work, recommendation path taught in both hook messages.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOT=${WALTER_TEST_ROOT:-$(mktemp -d)}
REPO="$ROOT/pairing-e2e"
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
has(){ case "$1" in *"$2"*) ok yes yes "$3";; *) ok no yes "$3 | missing [$2]";; esac; }
hasnt(){ case "$1" in *"$2"*) ok yes no "$3 | unexpected [$2]";; *) ok no no "$3";; esac; }

rm -rf "$REPO"; mkdir -p "$REPO"; cd "$REPO" || exit 1
git init -q . && git commit -q --allow-empty -m init
backlog init "pairinge2e" --agent-instructions none --check-branches false --include-remote false >/dev/null 2>&1
sed -i '' 's/^statuses: .*/statuses: ["Triage", "To Do", "In Progress", "Pairing", "Blocked", "Needs Attention", "Review", "Done"]/' backlog/config.yml
grep -q 'Pairing' backlog/config.yml || { echo "SETUP FAILED"; exit 1; }

mkdir -p .board backlog/decisions
cat > .board/config.json <<'EOF'
{ "test_command": "true", "review_status": "Review", "human_gated_statuses": ["Done"],
  "triage_status": "Triage", "blocked_status": "Blocked", "human_attention_status": "Needs Attention",
  "decisions_dir": "backlog/decisions", "dod_baseline": [] }
EOF
echo "setup: no pairing_status key in config — exercising the jq default"

backlog task create "long conversation" >/dev/null 2>&1
backlog task create "ordinary work" >/dev/null 2>&1
# The human puts task-1 in Pairing. The CLI has no such restriction; the hook does.
backlog task edit task-1 --status "Pairing" >/dev/null 2>&1
ok "$(backlog task list --plain -s Pairing 2>/dev/null | grep -c 'long conversation' || true)" "1" "human can place a task in Pairing via the CLI"

echo; echo "== guard-transitions: agent cannot enter Pairing =="
gt(){ jq -nc --arg c "$1" '{tool_input:{command:$c}}' | bash "$PLUGIN/hooks/scripts/guard-transitions.sh" 2>/dev/null; echo $?; }
gterr(){ jq -nc --arg c "$1" '{tool_input:{command:$c}}' | bash "$PLUGIN/hooks/scripts/guard-transitions.sh" 2>&1 >/dev/null; }
P="Pair""ing"
ok "$(gt "backlog task edit task-2 -s $P")" "2" "setting Pairing blocked (-s)"
ok "$(gt "backlog task edit task-2 --status=$P")" "2" "setting Pairing blocked (--status=)"
ERR=$(gterr "backlog task edit task-2 -s $P")
has "$ERR" "human-only column" "denial names the column as human-only"
has "$ERR" "RECOMMEND" "denial teaches the recommendation path"
has "$ERR" "Needs Attention" "denial names the park-and-stop fallback"
hasnt "$ERR" "Move the task to 'Review' instead" "denial does NOT reuse the Done-gate text"
echo "  --- agent exits are still allowed ---"
ok "$(gt "backlog task edit task-1 -s Review")" "0" "agent may move a task OUT of Pairing to Review"
ok "$(gt "backlog task edit task-1 -s Blocked")" "0" "agent may move a task OUT to Blocked"
D="Do""ne"
ok "$(gt "backlog task edit task-1 -s $D")" "2" "Done gate still fires"
ERRD=$(gterr "backlog task edit task-1 -s $D")
has "$ERRD" "Move the task to 'Review' instead" "Done gate keeps its own text"

echo; echo "== stop-gate: Pairing does not count as dangling =="
S1=$(jq -nc '{session_id:"p-e2e-1",stop_hook_active:false}' | bash "$PLUGIN/hooks/scripts/stop-gate.sh" 2>&1)
ok "${S1:-empty}" "empty" "task in Pairing alone -> no block"

echo; echo "== stop-gate: In Progress still blocks, and teaches the recommendation =="
backlog task edit task-2 --status "In Progress" >/dev/null 2>&1
S2=$(jq -nc '{session_id:"p-e2e-2",stop_hook_active:false}' | bash "$PLUGIN/hooks/scripts/stop-gate.sh" 2>&1)
ok "$(printf '%s' "$S2" | jq -r '.decision // "none"')" "block" "In Progress still blocks"
has "$S2" "1 task(s) still In Progress" "Pairing task excluded from the count"
has "$S2" "recommend 'Pairing'" "block message teaches the recommendation"
has "$S2" "'Pairing' is human-only" "block message states the agent may not set it"

echo; echo "== session-start: Pairing rendered as active work =="
SS=$(echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1)
has "$SS" "Pairing (open thread with the human" "Pairing section rendered"
has "$SS" "long conversation" "Pairing task shown in full detail"
has "$SS" "WITHOUT moving them to In Progress" "section states code work is allowed in place"
has "$SS" "In Progress (your current focus" "In Progress section still rendered"
has "$SS" "ONE active commitment at a time" "focus rule counts both active columns"
has "$SS" "'Pairing' is human-only" "rules footer teaches the recommendation"

echo; echo "== session-start: Pairing alone suppresses the pull-new-work nudge =="
backlog task edit task-2 --status "To Do" >/dev/null 2>&1
SS2=$(echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1)
has "$SS2" "Pairing (open thread with the human" "Pairing still rendered"
hasnt "$SS2" "No task is active" "does not tell the agent to pull new work"
hasnt "$SS2" "In Progress (your current focus" "no empty In Progress section"

echo; echo "== session-start: empty board restores the nudge =="
backlog task edit task-1 --status "To Do" >/dev/null 2>&1
SS3=$(echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1)
has "$SS3" "No task is active. Pull ONE task from To Do" "nudge returns when nothing is active"

echo; echo "== custom pairing_status name is honoured =="
backlog task edit task-1 --status "Pairing" >/dev/null 2>&1
sed -i '' 's/"triage_status": "Triage",/"triage_status": "Triage", "pairing_status": "Deliberating",/' .board/config.json
jq -e '.pairing_status == "Deliberating"' .board/config.json >/dev/null || { echo "config rewrite failed"; exit 1; }
ok "$(gt "backlog task edit task-2 -s Deliberating")" "2" "custom name is the gated one"
ok "$(gt "backlog task edit task-2 -s $P")" "0" "default name no longer gated once overridden"
SS4=$(echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1)
hasnt "$SS4" "Deliberating (open thread" "no section for a column with no tasks"

echo; echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
rm -f /tmp/walter-stop-p-e2e-*
[ "$FAIL" -eq 0 ]
