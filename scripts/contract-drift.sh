#!/usr/bin/env bash
# Report how a repo's installed walter contract differs from the current template.
#
# This is a REPORT, not a gate. It always exits 0 on a readable repo, and it never
# emits a "current" verdict: BD-34 recorded that the upgrade check's silent no-op
# success told two repos they were fine while they carried drift, and BD-40 found
# the same hole one block over. Every run ends by naming what it did NOT judge.
#
# It also does not repair anything. Blocks carry legitimate per-repo adaptation
# (Riots-Vasco's per-song firewall, ShannonAndTheRiots' "took it for a spin in
# actual music production"), and a refresh that flattens those is worse than the
# drift. Deciding which side of that line a line falls on is the human's job.
set -uo pipefail

usage() { echo "usage: $(basename "$0") <repo-dir> [template.md]" >&2; exit 2; }

REPO=${1:-}; [ -n "$REPO" ] || usage
TEMPLATE=${2:-"$(dirname "${BASH_SOURCE[0]}")/../templates/claude-md-section.md"}

CONTRACT="$REPO/CLAUDE.md"
[ -f "$CONTRACT" ] || { echo "no CLAUDE.md in $REPO" >&2; exit 2; }
[ -f "$TEMPLATE" ] || { echo "no template at $TEMPLATE" >&2; exit 2; }

# The contract section only, from its heading to the next h2.
section() {
  awk '/^## Board discipline/{f=1} f&&/^## /&&!/^## Board discipline/{exit} f{print}' "$1"
}
# Bullet lines belonging to one **Block**, whitespace-collapsed for comparison.
bullets() {
  awk -v want="$2" '
    /^\*\*/ { inblk = (index($0, want) == 1) ; next }
    inblk && /^- / { gsub(/[ \t]+/, " "); sub(/[ \t]+$/, ""); print }
  ' "$1"
}

# Every line belonging to one **Block**, bullets or not. The fill-in slots are not
# always bullets ({{WORKING_STYLE_NOTES}} sits on its own line), so the slot test
# has to look at the whole block or it silently reports adaptation as drift.
block_body() {
  awk -v want="$2" '
    /^\*\*/ { inblk = (index($0, want) == 1) ; next }
    inblk { print }
  ' "$1"
}

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT
section "$CONTRACT" > "$TMP/repo"
section "$TEMPLATE" > "$TMP/tpl"

[ -s "$TMP/repo" ] || { echo "$REPO: no '## Board discipline' section in CLAUDE.md — not onboarded, or the contract was renamed."; exit 0; }

echo "Contract drift report: $REPO"
echo "Template: $TEMPLATE"
echo

UNJUDGED=""
note_unjudged() { UNJUDGED="${UNJUDGED}  - $1"$'\n'; }

# Walk the template's blocks. A block the template does not define is reported
# separately below rather than silently ignored.
while IFS= read -r BLOCK; do
  echo "$BLOCK"

  if ! grep -qF -e "$BLOCK" "$TMP/repo"; then
    echo "  DRIFT  block is absent from the repo contract"
    echo
    continue
  fi

  bullets "$TMP/tpl"  "$BLOCK" > "$TMP/tb"
  bullets "$TMP/repo" "$BLOCK" > "$TMP/rb"

  if block_body "$TMP/tpl" "$BLOCK" | grep -q '{{'; then
    echo "  SKIP   contains fill-in slots; its content is per-repo by design"
    note_unjudged "$BLOCK — fill-in slots, never comparable"
    echo
    continue
  fi

  MISSING=0
  while IFS= read -r L; do
    [ -n "$L" ] || continue
    grep -qxF -e "$L" "$TMP/rb" || { echo "  MISSING  $L"; MISSING=$((MISSING+1)); }
  done < "$TMP/tb"

  EXTRA=0
  while IFS= read -r L; do
    [ -n "$L" ] || continue
    grep -qxF -e "$L" "$TMP/tb" || { echo "  REPO-ONLY  $L"; EXTRA=$((EXTRA+1)); }
  done < "$TMP/rb"

  [ "$MISSING" -eq 0 ] && [ "$EXTRA" -eq 0 ] && echo "  matches the template verbatim"
  [ "$EXTRA" -gt 0 ] && note_unjudged "$BLOCK — $EXTRA repo-only line(s): adaptation to keep, or stale wording to replace?"
  echo
done < <(grep '^\*\*' "$TMP/tpl")

# Blocks the repo has and the template does not. Never silently dropped.
while IFS= read -r BLOCK; do
  grep -qF -e "$BLOCK" "$TMP/tpl" || {
    echo "$BLOCK"
    echo "  REPO-ONLY BLOCK  not in the template"
    note_unjudged "$BLOCK — whole block exists only in this repo"
    echo
  }
done < <(grep '^\*\*' "$TMP/repo")

echo "NOT EXAMINED — this report cannot tell you these are fine:"
if [ -n "$UNJUDGED" ]; then printf '%s' "$UNJUDGED"; else echo "  - (nothing)"; fi
cat <<'EOF'
  - Prose outside the ** blocks, including the section preamble.
  - Whether a MISSING line is genuinely absent or merely reworded. Comparison is
    verbatim after whitespace collapse; a rewritten bullet reads as MISSING plus
    REPO-ONLY, and only a human can tell those apart from real drift.
  - Anything outside the '## Board discipline' section.
  - .board/config.json and backlog/config.yml. Steps 1 and 3 of the upgrade check
    cover those; this script does not read them.
EOF
