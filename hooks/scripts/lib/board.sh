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

# The repo's real status list, one per line. 1.50.1 prints it comma-separated.
# Memoised: hooks are short-lived, so this costs one process per invocation.
board_statuses() {
  if [ -z "${BOARD_STATUSES_CACHE+x}" ]; then
    BOARD_STATUSES_CACHE=$(backlog config get statuses 2>/dev/null |
      tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')
  fi
  printf '%s\n' "$BOARD_STATUSES_CACHE"
}

# Does the board actually have this column? BD-19: the hooks advertised columns the
# repo had never created, so the agent was told to use exits the CLI would reject.
# Unknown or unreadable list returns true — a CLI change must not silently strip
# guidance. Never call this from guard-transitions.sh: that runs on every Bash call.
board_has_status() {
  local LIST
  LIST=$(board_statuses)
  [ -n "$LIST" ] || return 0
  printf '%s\n' "$LIST" | grep -qixF "$1"
}

board_path_is_task_file() {
  printf '%s' "$1" | grep -Eq "$BOARD_TASK_FILE_RE"
}

# Bash-side writes that the Write/Edit guard would have caught: redirects, tee,
# sed -i, mv/cp/rm aimed at task files. String-level, not a shell parser.
board_cmd_writes_task_file() {
  printf '%s' "$1" | grep -qiE "(>>?|\btee\b|\bsed\b[^|;&]*-i|\bmv\b|\bcp\b|\brm\b)[^|;&]*${BOARD_TASK_DIR}"
}

# Cheap pre-filter: a board-tool invocation that MUTATES a status?
# The status flag alone isn't enough — `task list -s <status>` and `board -s <status>`
# are read-only filters. BD-18: matching those denied the agent the CLI's own status
# filter, which it then learned to avoid. Requires a mutating subcommand.
# Residual false positive: one command line mixing a read-only filter with an unrelated
# edit still matches. String-level, not a shell parser; fails safe.
board_cmd_touches_status() {
  printf '%s' "$1" | grep -Eq "${BOARD_TOOL}[[:space:]]+(task|tasks)[[:space:]]+(edit|create)([[:space:]]|$)" &&
    printf '%s' "$1" | grep -Eq '(^|[[:space:]])(-s|--status)([[:space:]=])'
}

# Does command $1 create a SUBTASK? Requires the mutating subcommand, exactly as
# board_cmd_touches_status does: `task list -p <parent>` is a read-only filter and
# must not match (BD-18 is what that lesson cost). `-p` is unambiguous under
# `task create` — the subcommand has no other -p.
# Subtasks are human-defined (BD-25): a batch the agent can extend is a batch the
# agent can grow without ever breaking the one-commitment rule.
# ONE regex, not two greps: the flag must follow the create in the SAME command
# segment. Checking the two conditions independently across the whole command
# matched any unrelated -p anywhere in it — `mkdir -p` beside a plain create was
# enough. Caught by this guard blocking the writing of its own tests, 2026-08-25.
# Residual false positive: a single segment mixing a create with an unrelated -p.
# String-level, not a shell parser; fails safe.
board_cmd_creates_subtask() {
  printf '%s' "$1" |
    grep -Eq "${BOARD_TOOL}[[:space:]]+(task|tasks)[[:space:]]+create[^|;&]*[[:space:]](-p|--parent)([[:space:]=])"
}

# Ids of the subtasks of $1, bare and deduped; empty if it has none.
board_subtask_ids() {
  backlog task list --plain -p "$1" 2>/dev/null | grep -oE "$BOARD_ID_RE" | tr -d ' ' | sort -uf
}

# Does command $1 set status $2? Matches -s X | -s "X" | --status=X, case-insensitive.
# Known false positive: the same shape inside quoted prose also matches. Fails safe.
board_cmd_sets_status() {
  printf '%s' "$1" | grep -Eiq "(^|[[:space:]])(-s|--status)[[:space:]=]+[\"']?${2}[\"']?"
}

# Hints embedded in agent-facing prompt text and guard denials.
board_mutate_hint() { echo "backlog task edit <id> [-s <status>] [--notes ...] [--ac ...] (or backlog task archive)"; }
board_create_hint() { echo "backlog task create \"...\" --ac \"...\""; }
