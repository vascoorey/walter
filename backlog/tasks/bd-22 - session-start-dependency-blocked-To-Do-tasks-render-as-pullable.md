---
id: BD-22
title: 'session-start: dependency-blocked To Do tasks render as pullable'
status: Review
assignee: []
created_date: '2026-08-23 02:18'
updated_date: '2026-08-25 11:31'
labels: []
dependencies: []
parent_task_id: BD-31
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The injection ends with 'Pull ONE task from To Do, set it In Progress before touching code' while rendering To Do tasks whose dependencies are unmet.

Riots-Vasco, live board: RIOTS-30, 31 and 32 sit in To Do, each depending on RIOTS-29, which is parked awaiting references only the human can supply. The agent recorded those dependencies itself via the CLI, so the hook is discarding information already on the board and inviting the agent to pull work it cannot finish.

backlog 1.50.1 has 'task list --ready' (only unblocked tasks with all dependencies completed), verified 2026-08-23. Fix: mark or demote blocked To Do lines in board_summary. Keep it inside lib/board.sh so BD-11 stays mechanical.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 To Do tasks with unmet dependencies are visibly distinguished or demoted
- [x] #2 New query stays inside lib/board.sh
- [x] #3 Boards with no dependencies render unchanged
- [x] #4 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #5 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DONE 2026-08-25 under BD-31.

Fix: board_summary now marks To Do lines whose dependencies are unmet, appending a bracketed note rather than hiding them. Marked and not demoted on purpose: a task that vanishes takes its reason with it, and the agent then cannot see why the dependency matters.

New query is board_ready_ids in lib/board.sh, wrapping the CLI ready filter, so BD-11 stays mechanical.

Semantics verified against 1.50.1 before building, not assumed: the ready filter spans EVERY column rather than just the pullable one, drops tasks with unmet dependencies, and keeps tasks that have none. That last property is what makes a dependency-free board render unchanged with no special case.

FAILS OPEN. An empty result from the ready filter is treated as unusable, never as nothing-is-ready. Without that, a CLI change would mark the entire board blocked, which is the exact failure BD-19 was about.

Implementation note: the awk pass takes the ready set comma-joined rather than newline-joined, because BSD awk rejects a newline inside a -v value. Cost one debugging round.

Verification: 6 assertions in bd31-e2e covering a dependent task marked, an independent task not marked, the upstream task itself not marked, the mark clearing once the upstream task completes, and a dependency-free board rendering unchanged while still listing its tasks.
<!-- SECTION:NOTES:END -->
