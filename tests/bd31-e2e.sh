#!/usr/bin/env bash
# BD-31 end-to-end: the hooks stop lying about the board.
# BD-20 green cache, BD-21 dod_baseline, BD-22 unmet dependencies, BD-24 papercuts.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOT=${WALTER_TEST_ROOT:-$(mktemp -d)}
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
has(){ case "$1" in *"$2"*) ok yes yes "$3";; *) ok no yes "$3 | missing [$2]";; esac; }
hasnt(){ case "$1" in *"$2"*) ok yes no "$3 | unexpected [$2]";; *) ok no no "$3";; esac; }

STATUSES='["Triage", "To Do", "In Progress", "Pairing", "Blocked", "Needs Attention", "Review", "Done"]'
mkboard(){ # $1=dirname  $2=extra config json (merged)  -> a real git repo + board
  local D="$ROOT/$1"
  rm -rf "$D"; mkdir -p "$D"; cd "$D" || exit 1
  git init -q . && git commit -q --allow-empty -m init
  backlog init "$1" --agent-instructions none --check-branches false --include-remote false >/dev/null 2>&1
  sed -i '' "s|^statuses: .*|statuses: $STATUSES|" backlog/config.yml
  mkdir -p .board backlog/decisions
  local EXTRA=${2:-}; [ -n "$EXTRA" ] || EXTRA='{}'
  printf '%s' "$EXTRA" | jq '{ test_command: "true", review_status: "Review",
    human_gated_statuses: ["Done"], triage_status: "Triage", blocked_status: "Blocked",
    human_attention_status: "Needs Attention", decisions_dir: "backlog/decisions",
    dod_baseline: [] } * .' > .board/config.json
}
ss(){ echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1; }
# A board whose config failed to generate would make half these assertions pass
# vacuously. Fail loudly instead.
cfgok(){ jq -e '.review_status == "Review"' .board/config.json >/dev/null 2>&1 ||
  { echo "  FATAL  .board/config.json is not valid in $(pwd)"; exit 1; }; }
# stop_hook_active=true so only Gate 1 (verification) runs, never land-the-plane.
sg(){ jq -nc --arg s "$1" '{session_id:$s,stop_hook_active:true}' | bash "$PLUGIN/hooks/scripts/stop-gate.sh" >/dev/null 2>&1; }
gtf(){ jq -nc --arg f "$1" '{tool_input:{file_path:$f}}' | bash "$PLUGIN/hooks/scripts/guard-task-files.sh" 2>&1 >/dev/null; }

echo "== BD-20: board writes must not bust the green cache =="
RUNS=/tmp/walter-bd31-runs; rm -f /tmp/walter-green-* "$RUNS"
mkboard bd31-cache "$(jq -nc --arg c "printf x >> $RUNS; true" '{test_command:$c}')"
echo "code" > src.sh
backlog task create "a task" >/dev/null 2>&1
git add -A && git commit -q -m base
runs(){ [ -f "$RUNS" ] && wc -c < "$RUNS" | tr -d ' ' || echo 0; }

sg s1; ok "$(runs)" "1" "first stop runs the verification command"
sg s1; ok "$(runs)" "1" "an unchanged tree hits the cache"
backlog task edit task-1 --notes "a note written mid-session" >/dev/null 2>&1
sg s1; ok "$(runs)" "1" "a turn that only writes to the board still hits the cache"
backlog task create "another task" >/dev/null 2>&1
sg s1; ok "$(runs)" "1" "creating a task does not bust it either"
echo "changed" >> src.sh
sg s1; ok "$(runs)" "2" "editing real code DOES bust it"
sg s1; ok "$(runs)" "2" "and re-stamps green"
echo "new" > other.sh
sg s1; ok "$(runs)" "3" "a new untracked source file busts it"

echo
echo "== BD-21: dod_baseline is surfaced, not inert =="
mkboard bd31-dod "$(jq -nc '{dod_baseline:["Tests pass","Docs updated"]}')"
cfgok
A=$(ss)
has "$A" "Definition of Done baseline" "the baseline block appears"
has "$A" "    - Tests pass" "each item is listed"
has "$A" "    - Docs updated" "every item, not just the first"
has "$A" "--ac at creation" "it says how to apply them"
mkboard bd31-nodod
cfgok
B=$(ss)
hasnt "$B" "Definition of Done baseline" "an empty baseline emits nothing"
has "$B" "Discovered work" "the rest of the footer is unaffected"

echo
echo "== BD-22: To Do with unmet dependencies is marked, not offered =="
mkboard bd31-deps
cfgok
backlog task create "upstream item" >/dev/null 2>&1
backlog task create "downstream item" --dep task-1 >/dev/null 2>&1
backlog task create "independent work" >/dev/null 2>&1
C=$(ss)
has "$C" "downstream item   [blocked: dependencies unmet]" "the dependent task is marked"
hasnt "$C" "independent work   [blocked" "a task with no dependencies is not marked"
hasnt "$C" "upstream item   [blocked" "the upstream task itself is not marked"
backlog task edit task-1 -s Done >/dev/null 2>&1
D=$(ss)
hasnt "$D" "[blocked: dependencies unmet]" "completing the blocker clears the mark"

mkboard bd31-nodeps
cfgok
backlog task create "one" >/dev/null 2>&1
backlog task create "two" >/dev/null 2>&1
E=$(ss)
hasnt "$E" "[blocked" "a board with no dependencies renders unchanged"
has "$E" "  TASK-1 - one" "and still lists its tasks normally"

echo
echo "== BD-24 item 3: the footer must agree with the repo's claim gate =="
mkboard bd31-gate "$(jq -nc '{claim_gate:true}')"
cfgok
backlog task create "unclaimed" >/dev/null 2>&1
F=$(ss)
has "$F" "ASK before setting anything In Progress" "the no-active-task line asks instead of telling"
hasnt "$F" "Pull ONE task from To Do" "and does not contradict itself"
has "$F" "Claiming is gated in this repo" "the footer states the gate"
has "$F" "not hook-enforced" "and is honest that it is contract-level"
mkboard bd31-nogate
cfgok
backlog task create "unclaimed" >/dev/null 2>&1
G=$(ss)
has "$G" "Pull ONE task from To Do" "an ungated repo keeps the original line"
hasnt "$G" "Claiming is gated" "and gains no gate wording"

echo
echo "== BD-24 item 4: the terminal column is capped, and says so =="
mkboard bd31-cap
cfgok
for i in $(seq 1 14); do backlog task create "done thing $i" >/dev/null 2>&1; done
for i in $(seq 1 14); do backlog task edit task-$i -s Done >/dev/null 2>&1; done
backlog task create "still open" >/dev/null 2>&1
H=$(ss)
ok "$(printf '%s\n' "$H" | grep -c 'done thing')" "10" "exactly the cap is rendered"
has "$H" "... and 4 more" "the omitted count is stated"
has "$H" "still open" "other columns are untouched"
mkboard bd31-undercap
cfgok
for i in 1 2 3; do backlog task create "small $i" >/dev/null 2>&1; done
for i in 1 2 3; do backlog task edit task-$i -s Done >/dev/null 2>&1; done
I=$(ss)
hasnt "$I" "and 0 more" "a column under the cap says nothing"
ok "$(printf '%s\n' "$I" | grep -c 'small ')" "3" "and renders in full"

echo
echo "== BD-24 items 1, 2: the task-file denial names the human handoff =="
J=$(gtf "backlog/tasks/task-1 - a thing.md")
has "$J" "never edit task files directly" "the denial still fires"
has "$J" "! prefix" "it names the bang-prefix route"
has "$J" "chmod +x" "and the executable bit that has already cost a human three attempts"
has "$J" "OUTSIDE backlog/" "and says where the script must live"
K=$(gtf "src/main.go")
ok "$(printf '%s' "$K" | wc -c | tr -d ' ')" "0" "an ordinary file is untouched"
grep -q 'chmod +x' "$PLUGIN/commands/onboard.md" && ok yes yes "onboard tells the interviewer to chmod the migration" || ok no yes "onboard chmod"
grep -q '"claim_gate": false' "$PLUGIN/commands/onboard.md" && ok yes yes "onboard writes the claim_gate key" || ok no yes "onboard claim_gate"

echo
echo "== BD-24 item 6: reading out of the task directory is not a write =="
bash "$PLUGIN/tests/cpprobe.sh" >/dev/null 2>&1
ok "$?" "0" "the mv/cp source-versus-destination probe passes (13 cases)"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
rm -f /tmp/walter-stop-s1 "$RUNS"
[ "$FAIL" -eq 0 ]
