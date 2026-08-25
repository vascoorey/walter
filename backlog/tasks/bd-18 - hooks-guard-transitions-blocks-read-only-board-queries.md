---
id: BD-18
title: 'hooks: guard-transitions blocks read-only board queries'
status: Review
assignee: []
created_date: '2026-08-23 02:17'
updated_date: '2026-08-25 11:11'
labels: []
dependencies: []
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
board_cmd_touches_status in hooks/scripts/lib/board.sh matches any command containing 'backlog' plus a status flag, so a read-only query that FILTERS by a human-gated column is denied as if it were a transition.

Observed in the wild, Riots-Vasco 2026-08-23: a 'backlog task list --plain' query filtered to the gated column was blocked with "'Done' is a human-gated transition. You may not set it." The agent recovered in one turn by rewriting to a grep, which returned nothing, so the false positive also cost a degraded answer. The lasting harm is that it teaches the agent to avoid the CLI's own status filter.

Fix: require a mutating subcommand ('task edit' / 'task create') before treating a status flag as a transition, or exclude 'task list' and 'board' explicitly. Regression test must cover both flag spellings against both list and edit.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Read-only status-filtered queries are not blocked
- [x] #2 Mutating transitions to gated columns are still blocked, both flag spellings
- [x] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Scope confirmed complete by the 2026-08-25 review, and confirmed NOT to cover the second production false positive. BD-18's scope was read-only status-filter queries reaching the transition matcher; current source requires an edit or create subcommand before it inspects a status flag, so that class is genuinely fixed, and the Riots-Vasco denial it addressed predates the BD-18 edit. The remaining Shannon false positive is a different predicate, the task-file write matcher, and belongs to BD-35. Recorded here so BD-35 is not closed as a duplicate of this and so this is not reopened for a defect it never covered.
<!-- SECTION:NOTES:END -->
