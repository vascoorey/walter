---
id: BD-22
title: 'session-start: dependency-blocked To Do tasks render as pullable'
status: To Do
assignee: []
created_date: '2026-08-23 02:18'
updated_date: '2026-08-25 05:46'
labels: []
dependencies: []
ordinal: 11000
parent_task_id: BD-31
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
- [ ] #1 To Do tasks with unmet dependencies are visibly distinguished or demoted
- [ ] #2 New query stays inside lib/board.sh
- [ ] #3 Boards with no dependencies render unchanged
- [ ] #4 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #5 README updated if behavior changed
<!-- AC:END -->
