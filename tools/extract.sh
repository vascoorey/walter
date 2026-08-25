#!/usr/bin/env bash
# Deterministic evidence extraction from Claude Code transcripts.
# Emits citable lines: <repo> <session8> <lineno> <iso-ts> | <payload>
set -uo pipefail
OUT=$1; shift
mkdir -p "$OUT"
# Repo label -> ~/.claude/projects transcript dir. A repo that has been renamed on disk
# keeps BOTH entries under one label: history lives under the old dir forever. Do not
# collapse these.
declare -a DIRS=(
  "automation-pal:-Users-vascoorey-Developer-automation-pal"
  "walter:-Users-vascoorey-Developer-board-discipline"
  "walter:-Users-vascoorey-Developer-walter"
  "riots-vasco:-Users-vascoorey-Riots-Vasco"
  "shannon:-Users-vascoorey-ShannonAndTheRiots"
)
for PAIR in "${DIRS[@]}"; do
  REPO=${PAIR%%:*}; DIR=$HOME/.claude/projects/${PAIR#*:}
  for F in "$DIR"/*.jsonl; do
    [ -f "$F" ] || continue
    S=$(basename "$F" .jsonl); S8=${S:0:8}
    jq -r --arg repo "$REPO" --arg s "$S8" '
      . as $r
      | (input_line_number) as $ln
      | ($r.timestamp // $r.snapshot.timestamp // "") as $ts
      | [ $repo, $s, ($ln|tostring), $ts ] as $cite
      | if $r.type == "attachment" and ($r.attachment.content|type) == "string"
        then { k: ("hook:" + ($r.attachment.hookName // $r.attachment.type // "?")), t: $r.attachment.content, c: $cite }
        elif $r.type == "user" and ($r.message.content|type) == "string"
        then { k: "human", t: $r.message.content, c: $cite }
        elif $r.type == "user" and ($r.message.content|type) == "array"
        then ($r.message.content[] | select(.type=="text") | { k: "human", t: .text, c: $cite })
        elif $r.type == "assistant" and ($r.message.content|type) == "array"
        then ($r.message.content[]
              | if .type=="tool_use" then { k: ("tool:" + .name), t: (.input|tostring), c: $cite }
                elif .type=="text" then { k: "assistant", t: .text, c: $cite }
                else empty end)
        else empty end
      | [ (.c|join(" ")), .k, (.t|gsub("\n";" ⏎ ")) ] | @tsv
    ' "$F" 2>/dev/null
  done
done
