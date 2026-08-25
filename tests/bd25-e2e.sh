#!/usr/bin/env bash
# BD-25 end-to-end: the unit of focus is a commitment, not a ticket.
# Covers the subtask-create denial, parent.sh, and how the hooks render a parent
# that is In Progress with its subtasks parked in To Do.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOT=${WALTER_TEST_ROOT:-$(mktemp -d)}
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
has(){ case "$1" in *"$2"*) ok yes yes "$3";; *) ok no yes "$3 | missing [$2]";; esac; }
hasnt(){ case "$1" in *"$2"*) ok yes no "$3 | unexpected [$2]";; *) ok no no "$3";; esac; }

CFG='{ "test_command": "true", "review_status": "Review", "human_gated_statuses": ["Done"],
  "triage_status": "Triage", "blocked_status": "Blocked", "human_attention_status": "Needs Attention",
  "decisions_dir": "backlog/decisions", "dod_baseline": [] }'

mkboard(){ # $1=dirname -> a real backlog board with every workflow column
  local D="$ROOT/$1"
  rm -rf "$D"; mkdir -p "$D"; cd "$D" || exit 1
  git init -q . && git commit -q --allow-empty -m init
  backlog init "$1" --agent-instructions none --check-branches false --include-remote false >/dev/null 2>&1
  sed -i '' 's/^statuses: .*/statuses: ["Triage", "To Do", "In Progress", "Pairing", "Blocked", "Needs Attention", "Review", "Done"]/' backlog/config.yml
  mkdir -p .board backlog/decisions
  printf '%s\n' "$CFG" > .board/config.json
}

gt(){ jq -nc --arg c "$1" '{tool_input:{command:$c}}' | bash "$PLUGIN/hooks/scripts/guard-transitions.sh" 2>/dev/null; echo $?; }
gterr(){ jq -nc --arg c "$1" '{tool_input:{command:$c}}' | bash "$PLUGIN/hooks/scripts/guard-transitions.sh" 2>&1 >/dev/null; }
ss(){ echo '{}' | bash "$PLUGIN/hooks/scripts/session-start.sh" 2>&1; }
sg(){ jq -nc --arg s "$1" '{session_id:$s,stop_hook_active:false}' | bash "$PLUGIN/hooks/scripts/stop-gate.sh" 2>&1; }

# The flag string the guard must catch, assembled at runtime. Written this way on
# purpose: spelled literally, these fixtures would trip the very guard under test
# when this file is created through a shell heredoc. That is a real property of a
# string-matching guard, not a quirk of the test.
P='-p'; LP='--parent'; CREATE='create'

echo "== the subtask-create denial =="
mkboard bd25-guard
ok "$(gt "backlog task $CREATE \"child\" $P task-1")" "2" "task create -p <parent>"
ok "$(gt "backlog task $CREATE \"child\" $LP task-1")" "2" "task create --parent <parent>"
ok "$(gt "backlog task $CREATE \"child\" $LP=task-1")" "2" "task create --parent=<parent>"
ok "$(gt "backlog tasks $CREATE \"child\" $P task-1")" "2" "the 'tasks' alias is covered"
ok "$(gt "cd sub && backlog task $CREATE \"child\" $P task-1")" "2" "prefixed by another command"
ok "$(gt "backlog task $CREATE \"child\" --ac \"x\" $P task-1 -l foo")" "2" "flag buried among other flags"

echo
echo "== read-only and ordinary creates must still pass (the BD-18 lesson) =="
ok "$(gt "backlog task list --plain $P task-1")" "0" "task list -p is a read-only filter"
ok "$(gt "backlog task list --plain $LP=task-1")" "0" "task list --parent= is a read-only filter"
ok "$(gt "backlog task $CREATE \"a top-level task\"")" "0" "task create with no parent flag"
ok "$(gt "backlog task $CREATE \"x\" --ac \"y\" -l alpha")" "0" "task create with unrelated flags"
ok "$(gt 'backlog task edit task-1 --notes "see task-2"')" "0" "an ordinary note still passes"

echo
echo "== the denial has to name the sanctioned route =="
E=$(gterr "backlog task $CREATE \"child\" $P task-1")
has "$E" "subtasks are human-defined" "denial states the rule"
has "$E" "'Triage'" "denial names the triage column by its configured name"
has "$E" "scripts/parent.sh" "denial hands over the parent.sh route"
has "$E" "ONE commitment" "denial explains what the rule protects"

echo
echo "== parent.sh end to end =="
mkboard bd25-parent
backlog task create "rich task" -d "a description with *markdown*" --ac "first" --ac "second" \
  --notes "notes that must survive" -l alpha,beta >/dev/null 2>&1
backlog task create "plain two" >/dev/null 2>&1
backlog task create "plain three" --dep task-1 >/dev/null 2>&1
backlog task edit task-1 --check-ac 1 >/dev/null 2>&1
BEFORE="$ROOT/bd25-before"; rm -rf "$BEFORE"; mkdir -p "$BEFORE"
( cd "$ROOT/bd25-parent/backlog/tasks" && cp -- *.md "$BEFORE/" )

OUT=$(bash "$PLUGIN/scripts/parent.sh" "the bundle" task-1 task-2 task-3 2>&1)
ok "$?" "0" "parent.sh exits clean"
has "$OUT" "Subtasks (3)" "the parent reports all three subtasks"
has "$OUT" "No duplicate task" "backlog doctor stays clean"
has "$OUT" "id and filename unchanged" "the script says what it did"
ok "$(backlog task list --plain -p task-4 | grep -cE '^[[:space:]]*[A-Za-z]+-[0-9]+')" "3" "the -p filter returns all three"

echo
echo "== nothing but the one frontmatter line changed =="
DIFFS=0; MISSING=0
for F in "$ROOT"/bd25-parent/backlog/tasks/*.md; do
  B="$BEFORE/$(basename "$F")"
  [ -f "$B" ] || continue
  grep -q '^parent_task_id: TASK-4$' "$F" || MISSING=$((MISSING+1))
  diff -q <(grep -v '^parent_task_id:' "$F") "$B" >/dev/null || DIFFS=$((DIFFS+1))
done
ok "$DIFFS" "0" "every bundled task is byte-identical apart from the inserted line"
ok "$MISSING" "0" "every bundled task actually carries the parent field"
ok "$(grep -c '^parent_task_id:' "$ROOT"/bd25-parent/backlog/tasks/task-1\ *.md)" "1" "the field is not duplicated"
has "$(cat "$ROOT"/bd25-parent/backlog/tasks/task-1\ *.md)" "- [x] #1 first" "a checked acceptance criterion survives as checked"
has "$(cat "$ROOT"/bd25-parent/backlog/tasks/task-1\ *.md)" "- [ ] #2 second" "an unchecked one survives as unchecked"
has "$(cat "$ROOT"/bd25-parent/backlog/tasks/task-1\ *.md)" "notes that must survive" "implementation notes survive"

echo
echo "== idempotent, and it refuses bad input without touching anything =="
cd "$ROOT/bd25-parent" || exit 1
bash "$PLUGIN/scripts/parent.sh" task-4 task-1 >/dev/null 2>&1
ok "$(grep -c '^parent_task_id:' "$ROOT"/bd25-parent/backlog/tasks/task-1\ *.md)" "1" "re-running does not duplicate the field"
SNAP=$(cat "$ROOT"/bd25-parent/backlog/tasks/task-2\ *.md)
BAD=$(bash "$PLUGIN/scripts/parent.sh" task-4 task-2 task-999 2>&1); RC=$?
ok "$RC" "1" "an unresolvable id is refused"
has "$BAD" "nothing was changed" "the refusal says nothing was changed"
ok "$(cat "$ROOT"/bd25-parent/backlog/tasks/task-2\ *.md)" "$SNAP" "the valid task in a refused batch is untouched"
SELF=$(bash "$PLUGIN/scripts/parent.sh" task-4 task-4 2>&1); RC=$?
ok "$RC" "1" "a task cannot be its own parent"
ok "$(bash "$PLUGIN/scripts/parent.sh" 2>&1 >/dev/null | head -1 | grep -c Usage)" "1" "bare invocation prints usage"
ok "$([ -x "$PLUGIN/scripts/parent.sh" ] && echo yes || echo no)" "yes" "the script ships executable"

echo
echo "== a repeated title must not silently make a second parent =="
mkboard bd25-rerun
backlog task create "alpha" >/dev/null 2>&1
backlog task create "beta" >/dev/null 2>&1
R1=$(bash "$PLUGIN/scripts/parent.sh" "the batch" task-1 task-2 2>&1)
has "$R1" "Subtasks (2)" "the first run bundles as normal"
BEFORE_COUNT=$(backlog task list --plain | grep -cE '^[[:space:]]*[A-Za-z]+-[0-9]+')
R2=$(bash "$PLUGIN/scripts/parent.sh" "the batch" task-1 task-2 2>&1); RC=$?
ok "$RC" "1" "re-running the same command is refused"
has "$R2" "already exists" "the refusal explains why"
has "$R2" "pass that id instead" "it says how to proceed"
has "$R2" "nothing was changed" "it confirms nothing was touched"
ok "$(backlog task list --plain | grep -cE '^[[:space:]]*[A-Za-z]+-[0-9]+')" "$BEFORE_COUNT" "no duplicate parent was created"
ok "$(backlog task list --plain -p task-3 | grep -cE '^[[:space:]]*[A-Za-z]+-[0-9]+')" "2" "the original parent still holds the batch"
# Passing the id rather than the title is the sanctioned way to add to a batch.
R3=$(bash "$PLUGIN/scripts/parent.sh" task-3 task-1 2>&1); RC=$?
ok "$RC" "0" "bundling under an existing parent BY ID still works"
# A title that merely ends with an existing title must still create.
R4=$(bash "$PLUGIN/scripts/parent.sh" "not the batch" task-1 2>&1); RC=$?
ok "$RC" "0" "a different title that merely contains an existing one still creates"

echo
echo "== an unrelated -p elsewhere in the command must not match =="
cd "$ROOT/bd25-guard" || exit 1
ok "$(gt "mkdir -p deep/nested && backlog task $CREATE \"one\"")" "0" "mkdir -p beside a plain create"
ok "$(gt "backlog task $CREATE \"one\"
mkdir -p somewhere")" "0" "the flag on a different line of the same command"
ok "$(gt "grep -p x file; backlog task $CREATE \"one\"")" "0" "another tool's -p in an earlier segment"
ok "$(gt "backlog task $CREATE \"one\" && mkdir -p after")" "0" "another tool's -p in a later segment"

echo
echo "== it finds the board from a subdirectory (the dogfood bug) =="
mkboard bd25-cwd
backlog task create "one" >/dev/null 2>&1
backlog task create "two" >/dev/null 2>&1
mkdir -p deep/nested/dir
cd "$ROOT/bd25-cwd/deep/nested/dir" || exit 1
SUB=$(bash "$PLUGIN/scripts/parent.sh" "from below" task-1 task-2 2>&1); RC=$?
ok "$RC" "0" "runs from a subdirectory instead of refusing"
has "$SUB" "Subtasks (2)" "it bundled against the right board"
has "$SUB" "using the board at" "it says which board it walked up to"
cd "$ROOT/bd25-cwd" || exit 1
TOP=$(bash "$PLUGIN/scripts/parent.sh" task-3 task-1 2>&1)
hasnt "$TOP" "using the board at" "no location notice when already at the root"

OUTSIDE="$ROOT/bd25-noboard"; rm -rf "$OUTSIDE"; mkdir -p "$OUTSIDE"
cd "$OUTSIDE" || exit 1
NB=$(bash "$PLUGIN/scripts/parent.sh" "nope" task-1 2>&1); RC=$?
ok "$RC" "1" "still refuses where there is no board at all"
has "$NB" "or any parent" "the refusal says it searched upward"

echo
echo "== session-start: subtasks of an active parent are not pullable work =="
cd "$ROOT/bd25-parent" || exit 1
backlog task edit task-4 -s "In Progress" >/dev/null 2>&1
A=$(ss)
has "$A" "part of this commitment, not new work" "the commitment line is emitted"
has "$A" "verification happens once, on the parent" "it says where verification lands"
has "$A" "Subtasks (3)" "the parent detail still lists the batch"

mkboard bd25-nosub
backlog task create "lonely" >/dev/null 2>&1
backlog task edit task-1 -s "In Progress" >/dev/null 2>&1
B=$(ss)
hasnt "$B" "part of this commitment" "a task with no subtasks renders unchanged"
has "$B" "### In Progress" "the In Progress section is still rendered"

echo
echo "== stop-gate: a parent counts as ONE commitment, not N =="
cd "$ROOT/bd25-parent" || exit 1
S=$(sg bd25-stop)
has "$S" "Land the plane before stopping" "the gate still blocks on an active parent"
has "$S" "1 task(s) still In Progress" "the parent counts as exactly one, not four"
hasnt "$S" "4 task(s)" "subtasks in To Do are not counted as dangling"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
rm -f /tmp/walter-stop-bd25-* 2>/dev/null
[ "$FAIL" -eq 0 ]
