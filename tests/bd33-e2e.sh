#!/usr/bin/env bash
# BD-33: the hooks must behave under macOS's system bash 3.2, not just homebrew bash 5.
# The other five suites invoke hooks through PATH bash, so they all ran under 5.3 and
# were structurally blind to 3.2-only failures. This one pins the interpreter.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SYS=/bin/bash
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
hasnt(){ case "$1" in *"$2"*) ok yes no "$3 | unexpected [$2]";; *) ok no no "$3";; esac; }

echo "== interpreter under test: $($SYS --version | head -1) =="
case "$($SYS --version | head -1)" in
  *"version 3."*) echo "   (this is the shell macOS actually ships)";;
  *) echo "   WARNING: /bin/bash is not 3.x here; this suite proves less than it should";;
esac
echo

mkrepo(){ # -> a scratch git repo with a board config, cwd set to it
  local D; D=$(mktemp -d); cd "$D" || exit 1
  git init -q .; echo v1 > code.sh; git add -A; git commit -q -m init
  mkdir -p .board
  printf '%s\n' '{"test_command":"true","review_status":"Review","human_gated_statuses":["Done"],"triage_status":"Triage"}' > .board/config.json
  printf '%s\n' "$D"
}

echo "== stop-gate: the lib-missing fail-open path =="
# Copy the hook WITHOUT lib/board.sh beside it. That is the path BD-33 is about:
# board_hash_exclude_pathspec is unavailable, so the EXCLUDES array stays empty.
STAGE=$(mktemp -d); mkdir -p "$STAGE/scripts"; cp "$PLUGIN/hooks/scripts/stop-gate.sh" "$STAGE/scripts/"
mkrepo >/dev/null
rm -f /tmp/walter-green-* 2>/dev/null; rm -f /tmp/walter-stop-* 2>/dev/null
ERR=$(echo '{"session_id":"bd33","stop_hook_active":true}' | $SYS "$STAGE/scripts/stop-gate.sh" 2>&1 >/dev/null); RC=$?
ok "$RC" "0" "exits 0 when the shared lib cannot be loaded"
hasnt "$ERR" "unbound variable" "no nounset abort on the empty exclude array"
hasnt "$ERR" "bad substitution" "no 3.2-incompatible parameter expansion"

echo
echo "== stop-gate: the cache still works under 3.2 with the lib present =="
RUNS=$(mktemp); mkrepo >/dev/null
printf '{"test_command":"printf x >> %s; true","review_status":"Review","human_gated_statuses":["Done"]}\n' "$RUNS" > .board/config.json
rm -f /tmp/walter-green-* 2>/dev/null
IN='{"session_id":"bd33b","stop_hook_active":true}'
runs(){ wc -c < "$RUNS" 2>/dev/null | tr -d ' '; }
echo "$IN" | $SYS "$PLUGIN/hooks/scripts/stop-gate.sh" >/dev/null 2>&1
ok "$(runs)" "1" "first stop runs verification"
echo "$IN" | $SYS "$PLUGIN/hooks/scripts/stop-gate.sh" >/dev/null 2>&1
ok "$(runs)" "1" "an unchanged tree hits the green cache under bash 3.2"
echo "CHANGED" >> code.sh
echo "$IN" | $SYS "$PLUGIN/hooks/scripts/stop-gate.sh" >/dev/null 2>&1
ok "$(runs)" "2" "a real code change still busts it under bash 3.2"

echo
echo "== every hook entry point survives bash 3.2 =="
mkrepo >/dev/null
for H in session-start.sh guard-transitions.sh guard-task-files.sh stop-gate.sh; do
  E=$(printf '{"tool_input":{"command":"ls","file_path":"src/x.go"},"session_id":"bd33c","stop_hook_active":true}' \
      | $SYS "$PLUGIN/hooks/scripts/$H" 2>&1 >/dev/null)
  hasnt "$E" "unbound variable" "$H: no nounset abort"
  hasnt "$E" "syntax error" "$H: no 3.2 syntax error"
done

echo
echo "== parent.sh runs under bash 3.2 =="
E=$($SYS "$PLUGIN/scripts/parent.sh" 2>&1 >/dev/null); RC=$?
hasnt "$E" "unbound variable" "parent.sh: no nounset abort on the usage path"
hasnt "$E" "syntax error" "parent.sh: no 3.2 syntax error"
ok "$RC" "2" "parent.sh with no arguments exits 2 with usage"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
rm -f /tmp/walter-stop-bd33* "$RUNS" 2>/dev/null
[ "$FAIL" -eq 0 ]
