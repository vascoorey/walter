#!/usr/bin/env bash
# BD-24 item 6: mv/cp destination-vs-source behaviour of board_cmd_writes_task_file.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/scripts/lib/board.sh"
D='backlog/tasks/'
check() { # $1=expected(BLOCKED|allowed) $2=command
  if board_cmd_writes_task_file "$2"; then R=BLOCKED; else R=allowed; fi
  if [ "$R" = "$1" ]; then printf '  PASS  %-8s %s\n' "$R" "$2"
  else printf '  FAIL  got %-8s want %-8s  %s\n' "$R" "$1" "$2"; FAILED=1; fi
}
FAILED=0
echo "reads out of the task directory must pass:"
check allowed "cp ${D}x.md /tmp/before/"
check allowed "cp -- ${D}*.md /tmp/before/"
check allowed "mv ${D}a.md /tmp/"
check allowed "cat ${D}a.md"
check allowed "grep -l foo ${D}*.md"
echo "writes into it must still be blocked:"
check BLOCKED "cp /tmp/x.md ${D}"
check BLOCKED "cp a.md ${D}b.md"
check BLOCKED "mv /tmp/a.md ${D}a.md"
check BLOCKED "sed -i '' s/x/y/ ${D}a.md"
check BLOCKED "rm ${D}a.md"
check BLOCKED "echo x > ${D}a.md"
check BLOCKED "cat foo | tee ${D}a.md"
check BLOCKED "printf x >> ${D}a.md"
exit $FAILED
