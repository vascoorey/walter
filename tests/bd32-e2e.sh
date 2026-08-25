#!/usr/bin/env bash
# BD-32: parent.sh must never leave a task file truncated, and must never report
# success for a write that failed. The happy path was already proven by the BD-25
# suite and by two live bundles; this suite is entirely about the failure path,
# which is the one the review's refuter dismissed for lack of an observed incident.
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }

# Pull set_parent out of the shipped script and exercise it directly. Sourcing the
# whole file would run the CLI; the function is the unit under test.
eval "$(sed -n '/^set_parent() {/,/^}/p' "$PLUGIN/scripts/parent.sh")"
type set_parent >/dev/null 2>&1 || { echo "FATAL: could not extract set_parent"; exit 1; }

mktask(){ # $1=path
  cat > "$1" <<'TASK'
---
id: TEST-1
title: a task with content worth not losing
status: To Do
labels: [alpha, beta]
dependencies: [TEST-9]
---

## Description

Body text that must survive byte for byte.

## Acceptance Criteria
- [x] #1 already checked
- [ ] #2 not yet

## Implementation Notes

Notes with a --- sequence inside the body that must not be mistaken for frontmatter.
TASK
}

D=$(mktemp -d)

echo "== happy path preserves everything but the added field =="
F="$D/task.md"; mktask "$F"; cp "$F" "$D/baseline.md"
set_parent "$F" "TEST-77"; ok "$?" "0" "returns success"
ok "$(grep -c '^parent_task_id: TEST-77' "$F")" "1" "parent_task_id inserted exactly once"
ok "$(diff <(grep -v '^parent_task_id:' "$F") "$D/baseline.md" >/dev/null 2>&1; echo $?)" "0" "every other byte is unchanged"
ok "$(grep -c 'must not be mistaken for frontmatter' "$F")" "1" "a --- inside the body is untouched"

echo
echo "== re-running is idempotent, not additive =="
set_parent "$F" "TEST-88"
ok "$(grep -c '^parent_task_id:' "$F")" "1" "still exactly one parent_task_id"
ok "$(grep -c '^parent_task_id: TEST-88' "$F")" "1" "and it holds the new parent"

echo
echo "== a file that is not frontmatter is refused, not mangled =="
G="$D/plain.md"; printf 'no frontmatter here\njust text\n' > G_TMP; mv G_TMP "$G"; cp "$G" "$D/plain-baseline.md"
set_parent "$G" "TEST-77"; ok "$?" "1" "returns failure when there is no frontmatter block"
ok "$(diff "$G" "$D/plain-baseline.md" >/dev/null 2>&1; echo $?)" "0" "and leaves the file exactly as it was"

echo
echo "== THE REGRESSION: a failed write must not destroy the file =="
# Simulate the write failing partway. A read-only DIRECTORY makes mktemp/mv fail,
# which is the closest reproducible stand-in for the disk-full / interrupted case.
RO="$D/readonly"; mkdir -p "$RO"; H="$RO/task.md"; mktask "$H"; cp "$H" "$D/ro-baseline.md"
BEFORE=$(wc -c < "$H" | tr -d ' ')
chmod 500 "$RO"
set_parent "$H" "TEST-77"; RC=$?
chmod 700 "$RO"
AFTER=$(wc -c < "$H" | tr -d ' ')
ok "$RC" "1" "reports FAILURE when it cannot write"
ok "$AFTER" "$BEFORE" "the task file is byte-for-byte its original size"
ok "$(diff "$H" "$D/ro-baseline.md" >/dev/null 2>&1; echo $?)" "0" "and its contents are intact"

echo
echo "== no temp files are left behind in the board directory =="
LEFT=$(ls -a "$D" 2>/dev/null | grep -c '^\.parent\.' || true)
ok "$LEFT" "0" "no .parent.* turds beside the task files"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
rm -rf "$D"
[ "$FAIL" -eq 0 ]
