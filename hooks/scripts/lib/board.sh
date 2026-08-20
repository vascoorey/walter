#!/usr/bin/env bash
# Board backend touchpoints: every place walter talks to the board tool.
# Hard-wired to the backlog CLI. BD-11 turns this boundary into a descriptor-driven
# adapter, so keep new backlog knowledge inside this file and that stays a
# mechanical change. BD-8 is why this file exists: the task-id pattern lived in two
# scripts, and updating only one silently disarms the stop-gate's land-the-plane check.
#
# Sourced by hook scripts. guard-transitions.sh runs on EVERY Bash tool call with a
# 10s timeout, so nothing here may do network I/O or anything slower than a local process.

BOARD_TOOL='backlog'

# Task ids as they appear at the start of `--plain` list lines: "  BD-14 - title".
# Anchored so id-shaped words inside a title don't match; optional .N is a subtask.
# Prefix-agnostic: repos set task_prefix freely.
BOARD_ID_RE='^[[:space:]]*[A-Za-z]+-[0-9]+(\.[0-9]+)?'

# Where task files live: anchored path regex (Write/Edit guard) and bare
# substring (bash-side command guard).
BOARD_TASK_FILE_RE='(^|/)backlog/tasks/[^/]+\.md$'
BOARD_TASK_DIR='backlog/tasks/'

board_available() { command -v backlog >/dev/null 2>&1; }

# Whole board, one line per task. `board --plain` doesn't exist in 1.50.1.
board_summary() {
  backlog board --plain 2>/dev/null || backlog task list --plain 2>/dev/null
}

# Raw list lines ("  BD-14 - title") for one status; empty output if none.
board_lines_in_status() {
  backlog task list --plain -s "$1" 2>/dev/null | grep -E "$BOARD_ID_RE" || true
}

# Bare ids for one status, deduped. -f because 1.50.1 prints ids uppercase.
board_ids_in_status() {
  board_lines_in_status "$1" | grep -oE "$BOARD_ID_RE" | tr -d ' ' | sort -uf
}

board_show() { backlog task "$1" --plain 2>/dev/null; }

board_path_is_task_file() {
  printf '%s' "$1" | grep -Eq "$BOARD_TASK_FILE_RE"
}

# Bash-side writes that the Write/Edit guard would have caught: redirects, tee,
# sed -i, mv/cp/rm aimed at task files. String-level, not a shell parser.
board_cmd_writes_task_file() {
  printf '%s' "$1" | grep -qiE "(>>?|\btee\b|\bsed\b[^|;&]*-i|\bmv\b|\bcp\b|\brm\b)[^|;&]*${BOARD_TASK_DIR}"
}

# Cheap pre-filter: a board-tool invocation that sets a status at all?
board_cmd_touches_status() {
  printf '%s' "$1" | grep -q "$BOARD_TOOL" &&
    printf '%s' "$1" | grep -Eq '(^|[[:space:]])(-s|--status)([[:space:]=])'
}

# Does command $1 set status $2? Matches -s X | -s "X" | --status=X, case-insensitive.
# Known false positive: the same shape inside quoted prose also matches. Fails safe.
board_cmd_sets_status() {
  printf '%s' "$1" | grep -Eiq "(^|[[:space:]])(-s|--status)[[:space:]=]+[\"']?${2}[\"']?"
}

# Hints embedded in agent-facing prompt text and guard denials.
board_mutate_hint() { echo "backlog task edit <id> [-s <status>] [--notes ...] [--ac ...] (or backlog task archive)"; }
board_create_hint() { echo "backlog task create \"...\" --ac \"...\""; }
