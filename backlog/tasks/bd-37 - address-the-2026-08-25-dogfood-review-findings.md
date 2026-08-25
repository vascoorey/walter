---
id: BD-37
title: address the 2026-08-25 dogfood review findings
status: In Progress
assignee: []
created_date: '2026-08-25 10:09'
updated_date: '2026-08-25 10:22'
labels: []
dependencies: []
ordinal: 26000
---

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Parked awaiting a routing decision from the human.

Done so far, 2 of 5 subtasks: BD-32 (parent.sh atomic rewrite) and BD-33 (bash 3.2-safe expansions in content_hash) are both fixed, evidenced and their criteria checked. 212 assertions green across seven suites, repo gate green under both homebrew bash 5.3 and /bin/bash 3.2. README swept for both changes.

Remaining: BD-34, BD-35, BD-36.

What I need: whether to commit BD-32 and BD-33 first, or go straight to firing a codex workflow scoped at BD-34 and BD-35. The agreed split was that BD-32 and BD-33 were surgical enough to do directly while BD-34 and BD-35 carry real unknowns worth fanning out on, and BD-36 is writing rather than investigation.

Move back to In Progress before resuming work.
<!-- SECTION:NOTES:END -->
