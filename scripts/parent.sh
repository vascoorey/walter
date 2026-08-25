#!/usr/bin/env bash
# walter: bundle existing tasks under a parent task, so ONE commitment can cover
# several tickets that must land together.
#
# HUMAN-RUN BY DESIGN. The task-file guard blocks agents from writing task files,
# correctly. An agent's job is to PROPOSE a bundle and hand over this command;
# you run it. That is what stops the agent growing its own scope indefinitely.
#
# Why a script rather than the CLI: backlog 1.50.1 has `task create -p <parent>`
# but NO --parent on `task edit`, so existing tasks cannot be re-parented.
#
# Verified against backlog 1.50.1 on 2026-08-25: the dotted subtask id (BD-1.2) is
# NOT load-bearing. The frontmatter field parent_task_id alone is enough — backlog
# lists the task under the parent's Subtasks, the -p filter finds it, and doctor
# stays clean. So this script never renames, never recreates and never archives:
# every task keeps its own id, its own filename and its own file contents byte for
# byte. A later `task edit` rewrites the frontmatter and preserves the field.
set -uo pipefail

ME=$(basename "$0")
usage() {
  cat >&2 <<USAGE
Usage: $ME <parent> <task-id> [<task-id> ...]

  <parent>    an existing task id to bundle under, OR a title to create a new
              parent from. Resolution is tried first: if it names a real task,
              that task is used and nothing is created.
  <task-id>   one or more existing tasks to place under the parent.

Every argument is resolved before any file is touched. Nothing is renamed,
recreated or archived; each task keeps its id, filename and contents.

  $ME BD-30 BD-20 BD-21 BD-22 BD-24
  $ME "hooks stop lying" BD-20 BD-21 BD-22 BD-24
USAGE
  exit 2
}

[ $# -ge 2 ] || usage
command -v backlog >/dev/null 2>&1 || { echo "$ME: backlog CLI not found." >&2; exit 1; }
# Walk up to the board root, the way the backlog CLI itself does, so this works
# from any subdirectory. Found by dogfooding on 2026-08-25: it refused from the
# wrong directory on its first real use, which is BD-24 item 1 all over again.
# Every path used later comes back absolute from `backlog task --plain`, so
# changing directory here cannot affect what gets written.
START=$PWD
while [ ! -d backlog ] && [ "$PWD" != / ]; do cd .. || break; done
[ -d backlog ] || { echo "$ME: no backlog/ directory in $START or any parent." >&2; exit 1; }
# Say which board is about to be modified when it is not the one you are standing in.
[ "$PWD" = "$START" ] || echo "$ME: using the board at $PWD" >&2

# `task create --plain` and `task <id> --plain` share one output shape:
#   line 1  File: <absolute path>
#   line 3  Task <ID> - <title>
# Emits "<ID>\t<FILE>", non-zero if the task does not resolve.
resolve() {
  local OUT ID FILE
  OUT=$(backlog task "$1" --plain 2>/dev/null) || return 1
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^Task \([^ ]*\) - .*/\1/p' | head -1)
  FILE=$(printf '%s\n' "$OUT" | sed -n 's/^File: //p' | head -1)
  [ -n "$ID" ] && [ -n "$FILE" ] && [ -f "$FILE" ] || return 1
  printf '%s\t%s\n' "$ID" "$FILE"
}

# --- Resolve the parent, creating it only if the argument names no existing task ---
PARENT_ARG=$1; shift
CREATED=false
if PARENT=$(resolve "$PARENT_ARG"); then
  :
else
  # A title that already names a task is almost always a re-run, not a request for
  # a second identical parent. Dogfood 2026-08-25: running the same command twice
  # created a duplicate parent and moved the whole batch onto it, leaving the first
  # one empty and orphaned. Refuse instead, before anything is touched.
  EXISTING=$(backlog task list --plain 2>/dev/null | awk -v t="$PARENT_ARG" '
    { line = $0; sub(/^[[:space:]]+/, "", line)
      i = index(line, " - "); if (i == 0) next
      if (substr(line, i + 3) == t) print substr(line, 1, i - 1) }')
  if [ -n "$EXISTING" ]; then
    echo "$ME: a task with this exact title already exists:" >&2
    printf '%s\n' "$EXISTING" | sed 's/^/  /' >&2
    echo "$ME: pass that id instead of the title to bundle under it, or pick a different title." >&2
    echo "$ME: nothing was changed." >&2
    exit 1
  fi
  OUT=$(backlog task create "$PARENT_ARG" --plain 2>&1) || {
    echo "$ME: could not create parent task \"$PARENT_ARG\":" >&2
    printf '%s\n' "$OUT" >&2
    exit 1
  }
  PARENT_ID=$(printf '%s\n' "$OUT" | sed -n 's/^Task \([^ ]*\) - .*/\1/p' | head -1)
  PARENT=$(resolve "$PARENT_ID") || { echo "$ME: created the parent but cannot re-read it." >&2; exit 1; }
  CREATED=true
fi
PARENT_ID=${PARENT%%$'\t'*}

# --- Validate EVERY child before touching a single file ---
# A half-applied bundle is worse than a refused one: the board would claim a
# commitment that does not exist.
FAILED=0
CHILDREN=()
for ARG in "$@"; do
  if ! ROW=$(resolve "$ARG"); then
    echo "$ME: no such task: $ARG" >&2
    FAILED=1
    continue
  fi
  CHILD_ID=${ROW%%$'\t'*}
  if [ "$CHILD_ID" = "$PARENT_ID" ]; then
    echo "$ME: $CHILD_ID cannot be its own parent." >&2
    FAILED=1
    continue
  fi
  CHILDREN+=("$ROW")
done
if [ "$FAILED" -ne 0 ]; then
  echo "$ME: nothing was changed." >&2
  $CREATED && echo "$ME: note that parent $PARENT_ID WAS created — archive it if you do not want it." >&2
  exit 1
fi

# --- Apply: rewrite parent_task_id inside the frontmatter block only ---
# Any existing parent_task_id is replaced, so re-running is idempotent and a task
# can be moved between parents. Everything outside the frontmatter is untouched.
set_parent() {
  local FILE=$1 PID=$2 TMP
  TMP=$(mktemp) || return 1
  awk -v p="$PID" '
    BEGIN { fm = 0; done = 0 }
    /^---$/ {
      fm++
      if (fm == 2 && !done) { print "parent_task_id: " p; done = 1 }
      print; next
    }
    fm == 1 && /^parent_task_id:[[:space:]]/ { next }
    { print }
    END { exit (done ? 0 : 1) }
  ' "$FILE" > "$TMP" || { rm -f "$TMP"; return 1; }
  cat "$TMP" > "$FILE"
  rm -f "$TMP"
}

echo "Bundling under $PARENT_ID$($CREATED && printf ' (newly created)')"
echo
for ROW in "${CHILDREN[@]}"; do
  CHILD_ID=${ROW%%$'\t'*}
  CHILD_FILE=${ROW#*$'\t'}
  if set_parent "$CHILD_FILE" "$PARENT_ID"; then
    printf '  %-14s now a subtask of %s (id and filename unchanged)\n' "$CHILD_ID" "$PARENT_ID"
  else
    echo "  $CHILD_ID  FAILED — no frontmatter block found in $CHILD_FILE" >&2
    FAILED=1
  fi
done

# --- Verify, and show it rather than claim it ---
echo
echo "=== backlog task $PARENT_ID --plain ==="
backlog task "$PARENT_ID" --plain 2>&1 | sed -n '/^Subtasks/,/^$/p'
echo "=== backlog doctor ==="
backlog doctor 2>&1
exit "$FAILED"
