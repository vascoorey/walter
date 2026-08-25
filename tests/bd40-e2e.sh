#!/usr/bin/env bash
# BD-40: walter 0.2.0 hook-blocked subtask creation in three repos whose contracts
# never mentioned subtasks, because the upgrade check tested ONE block (State honesty)
# and reported the repo current. contract-drift.sh replaces that verdict with a report.
#
# The properties worth defending are not "it finds drift" but:
#   - it never emits a "current" verdict, so a passing run cannot be mistaken for safety
#   - it names what it did NOT judge, every time
#   - it reports per-repo adaptation as unjudged, never as drift to be flattened
set -uo pipefail
PLUGIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DRIFT="$PLUGIN/scripts/contract-drift.sh"
TPL="$PLUGIN/templates/claude-md-section.md"
PASS=0; FAIL=0
ok(){ if [ "$1" = "$2" ]; then echo "  PASS  $3"; PASS=$((PASS+1)); else echo "  FAIL  $3 | expected [$2] got [$1]"; FAIL=$((FAIL+1)); fi; }
has(){ case "$1" in *"$2"*) ok yes yes "$3";; *) ok no yes "$3 | missing [$2]";; esac; }
hasnt(){ case "$1" in *"$2"*) ok yes no "$3 | unexpected [$2]";; *) ok no no "$3";; esac; }

mkrepo(){ # $1 = CLAUDE.md body -> prints repo dir
  local D; D=$(mktemp -d "${WALTER_TEST_ROOT:-${TMPDIR:-/tmp}}/bd40.XXXXXX")
  printf '%s\n' "$1" > "$D/CLAUDE.md"
  printf '%s\n' "$D"
}

echo "== the BD-40 shape: current State honesty, pre-BD-25 Focus =="
# This is the exact condition that passed the old check in all three live repos.
DRIFTED=$(mkrepo "$(printf '%s\n' \
  '## Board discipline (NON-NEGOTIABLE)' '' \
  'The Backlog.md board is the single source of truth for intent and state. Hooks enforce the hard rules; the rest is on you to follow exactly.' '' \
  '**Focus**' \
  '- ONE active task at a time, counting `In Progress` and `Pairing` together.' \
  '- Stay on the claimed task until it reaches Review. Do not expand its scope.' '' \
  '**State honesty**' \
  '- Update status in real time — the moment reality changes, not batched at the end.' \
  '- `In Progress` means actively executing. It never survives a stop.' \
  '- Blocked on something external? Set `Blocked` and note the impediment on the task.' \
  '- You may set at most `Review`. `Done` is human-only (hook-enforced).')")
OUT=$(bash "$DRIFT" "$DRIFTED" "$TPL" 2>&1); RC=$?
ok "$RC" "0" "a drifted repo is reported, not gated: exit 0"
has "$OUT" "MISSING  - ONE active commitment at a time" "the commitment rule is reported missing"
has "$OUT" "You may not create a subtask (hook-enforced)" "the hook-enforced subtask rule is reported missing"
has "$OUT" "A parent's subtasks are work you have already claimed" "the never-pull-a-subtask rule is reported missing"
has "$OUT" "REPO-ONLY  - ONE active task at a time" "the stale pre-BD-25 wording is shown beside it"
hasnt "$OUT" "current" "the word 'current' is never used as a verdict"

echo
echo "== the property that killed the old check: no silent pass =="
CLEAN=$(mkrepo "$(sed -n '/^## Board discipline/,$p' "$TPL")")
OUT=$(bash "$DRIFT" "$CLEAN" "$TPL" 2>&1)
has "$OUT" "matches the template verbatim" "an identical block is reported as identical"
has "$OUT" "NOT EXAMINED" "even a fully matching repo still reports what was not examined"
has "$OUT" "Prose outside the ** blocks" "the unexaminable prose is named"
has "$OUT" ".board/config.json and backlog/config.yml" "the config files it does not read are named"
hasnt "$OUT" "invalid option" "bullet lines starting with '- ' are not eaten as grep options"

echo
echo "== identical lines are not reported as both missing and repo-only =="
# The first cut had exactly this bug: grep swallowed '- ...' as an option, every
# lookup failed, and every line was printed twice under opposite labels.
# Anchored: the NOT EXAMINED boilerplate mentions MISSING twice by design.
M=$(printf '%s\n' "$OUT" | grep -c '^  MISSING' 2>/dev/null || true)
ok "$M" "0" "a verbatim-matching contract yields zero MISSING lines"

echo
echo "== adaptation is surfaced for a human, never called drift =="
ADAPTED=$(mkrepo "$(printf '%s\n' \
  '## Board discipline (NON-NEGOTIABLE)' '' \
  '**Board integrity**' \
  '- All board mutations go through the `backlog` CLI (hook blocks direct task-file edits).' \
  '- `lyrics.md` is never edited without the user'"'"'s express permission.')")
OUT=$(bash "$DRIFT" "$ADAPTED" "$TPL" 2>&1)
has "$OUT" "REPO-ONLY  - \`lyrics.md\` is never edited" "the repo-specific line is shown"
has "$OUT" "adaptation to keep, or stale wording to replace?" "and handed to the human as unjudged"
hasnt "$OUT" "DRIFT  block is absent from the repo contract
  REPO-ONLY  - \`lyrics.md\`" "adaptation is not labelled drift"

echo
echo "== a block the repo dropped entirely =="
has "$OUT" "DRIFT  block is absent from the repo contract" "a missing block is reported as absent"

echo
echo "== a block the template has never heard of =="
EXTRA=$(mkrepo "$(printf '%s\n' \
  '## Board discipline (NON-NEGOTIABLE)' '' \
  '**Mastering handoff**' \
  '- The reference mix is the authority.')")
OUT=$(bash "$DRIFT" "$EXTRA" "$TPL" 2>&1)
has "$OUT" "REPO-ONLY BLOCK  not in the template" "a repo-only block is reported"
has "$OUT" "whole block exists only in this repo" "and named in the NOT EXAMINED list"

echo
echo "== fill-in slots are never compared =="
OUT=$(bash "$DRIFT" "$CLEAN" "$TPL" 2>&1)
has "$OUT" "SKIP   contains fill-in slots" "slot-bearing blocks are skipped"
has "$OUT" "fill-in slots, never comparable" "and named as permanently unjudgeable"
# {{WORKING_STYLE_NOTES}} is not a bullet; an earlier cut missed it and reported
# every repo's working-style notes as drift.
SLOTS=$(printf '%s\n' "$OUT" | grep -c 'SKIP   contains fill-in slots' 2>/dev/null || true)
ok "$SLOTS" "2" "both slot-bearing blocks are caught, bullet or not"

echo
echo "== unreadable inputs fail loudly, not silently =="
EMPTY=$(mktemp -d)
E=$(bash "$DRIFT" "$EMPTY" "$TPL" 2>&1); RC=$?
ok "$RC" "2" "a repo with no CLAUDE.md exits 2"
has "$E" "no CLAUDE.md" "and says so"
NOSEC=$(mkrepo "# Just a readme heading")
OUT=$(bash "$DRIFT" "$NOSEC" "$TPL" 2>&1); RC=$?
ok "$RC" "0" "a CLAUDE.md with no contract section is not an error"
has "$OUT" "not onboarded, or the contract was renamed" "and explains which it might be"
E=$(bash "$DRIFT" 2>&1); RC=$?
ok "$RC" "2" "no arguments exits 2 with usage"
has "$E" "usage:" "and prints usage"

echo
echo "== macOS system bash 3.2 =="
E=$(/bin/bash "$DRIFT" "$DRIFTED" "$TPL" 2>&1 >/dev/null)
hasnt "$E" "unbound variable" "no nounset abort under /bin/bash"
hasnt "$E" "syntax error" "no 3.2 syntax error"
OUT32=$(/bin/bash "$DRIFT" "$DRIFTED" "$TPL" 2>/dev/null)
has "$OUT32" "MISSING  - ONE active commitment at a time" "3.2 produces the same finding"

echo
echo "================================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
