#!/usr/bin/env bash
# BD-18 end-to-end: read-only board queries must not be blocked as transitions,
# while every mutating path stays blocked exactly as before.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOT=${WALTER_TEST_ROOT:-$(mktemp -d)}
REPO="$ROOT/bd18-e2e"
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
has(){ case "$1" in *"$2"*) ok yes yes "$3";; *) ok no yes "$3 | missing [$2]";; esac; }

rm -rf "$REPO"; mkdir -p "$REPO/.board"; cd "$REPO" || exit 1
cat > .board/config.json <<'EOF'
{ "test_command": "true", "review_status": "Review", "human_gated_statuses": ["Done"],
  "triage_status": "Triage", "blocked_status": "Blocked", "human_attention_status": "Needs Attention",
  "decisions_dir": "backlog/decisions", "dod_baseline": [] }
EOF

gt(){ jq -nc --arg c "$1" '{tool_input:{command:$c}}' | bash "$PLUGIN/hooks/scripts/guard-transitions.sh" 2>/dev/null; echo $?; }
gterr(){ jq -nc --arg c "$1" '{tool_input:{command:$c}}' | bash "$PLUGIN/hooks/scripts/guard-transitions.sh" 2>&1 >/dev/null; }

echo "== read-only queries must pass (the BD-18 regression) =="
ok "$(gt 'backlog task list --plain -s Done')" "0" "task list -s <gated>"
ok "$(gt 'backlog task list --plain --status Done')" "0" "task list --status <gated>"
ok "$(gt 'backlog task list --plain --status=Done')" "0" "task list --status=<gated>"
ok "$(gt 'backlog task list --plain -s "In Progress" -s Review')" "0" "task list with two status filters"
ok "$(gt 'backlog board -s Done')" "0" "board -s <gated>"
ok "$(gt 'backlog task list -s Pairing')" "0" "task list filtered to the pairing column"
# Verbatim from the Riots-Vasco transcript, 2026-08-23, the command that was blocked.
ok "$(gt 'backlog task list --plain -s Done 2>&1 | tail -6; echo "--- not done:"; backlog task list --plain -s "In Progress" -s Review 2>&1 | tail -4')" "0" "the exact command observed being blocked in the wild"

echo
echo "== mutating transitions stay blocked =="
ok "$(gt 'backlog task edit task-1 -s Done')" "2" "task edit -s <gated>"
ok "$(gt 'backlog task edit task-1 --status Done')" "2" "task edit --status <gated>"
ok "$(gt 'backlog task edit task-1 --status=Done')" "2" "task edit --status=<gated>"
ok "$(gt 'backlog task edit task-1 -s "Done"')" "2" "task edit -s quoted <gated>"
ok "$(gt 'backlog tasks edit task-1 -s Done')" "2" "the 'tasks' alias is covered"
ok "$(gt 'backlog task create "new thing" -s Done')" "2" "task create -s <gated>"
ok "$(gt 'cd sub && backlog task edit task-1 -s Done')" "2" "prefixed by another command"
ERR=$(gterr 'backlog task edit task-1 -s Done')
has "$ERR" "human-gated transition" "gated denial text intact"
has "$ERR" "Move the task to 'Review' instead" "gated denial still teaches Review"

echo
echo "== pairing entry stays blocked, exits stay open =="
ok "$(gt 'backlog task edit task-1 -s Pairing')" "2" "task edit -s Pairing"
ok "$(gt 'backlog task edit task-1 --status=Pairing')" "2" "task edit --status=Pairing"
ERRP=$(gterr 'backlog task edit task-1 -s Pairing')
has "$ERRP" "human-only column" "pairing denial text intact"
ok "$(gt 'backlog task edit task-1 -s Review')" "0" "non-gated status still allowed"
ok "$(gt 'backlog task edit task-1 -s "Needs Attention"')" "0" "parking still allowed"

echo
echo "== unrelated guards unaffected =="
ok "$(gt 'sed -i "" s/x/y/ backlog/tasks/task-1.md')" "2" "shell write to a task file still blocked"
ok "$(gt 'echo hi > TODO.md')" "2" "rogue TODO.md still blocked"
ok "$(gt 'ls -la && git status')" "0" "benign command passes"
ok "$(gt 'backlog task task-1 --plain')" "0" "read-only task show passes"

echo
echo "== documented residual: compound line mixing a filter with an edit fails safe =="
ok "$(gt 'backlog task list -s Done && backlog task edit task-1 --notes "x"')" "2" "compound still blocks (known, fails safe)"

echo
echo "== fail-open =="
rm -f .board/config.json
ok "$(gt 'backlog task edit task-1 -s Done')" "0" "no .board/config.json -> guard is inert"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
