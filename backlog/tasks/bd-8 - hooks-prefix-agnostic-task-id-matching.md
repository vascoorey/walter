---
id: BD-8
title: 'hooks: prefix-agnostic task-id matching'
status: Done
assignee: []
created_date: '2026-08-20 11:08'
updated_date: '2026-08-20 11:14'
labels:
  - stop-gate
dependencies: []
ordinal: 7.8125
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered 2026-08-20 while preparing the prefix-migration dogfood, which it blocks. stop-gate.sh (Gate 2 In Progress count) and session-start.sh (In Progress id extraction, parked-task listings) grep 'task-[0-9]+' — any board with a custom task_prefix makes Gate 2 silently pass and session-start miss tasks. Fix: anchor on the --plain list line shape instead, e.g. ^[[:space:]]*[A-Za-z]+-[0-9]+ (prefix-agnostic, avoids false matches on words like gpt-5 inside titles).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 stop-gate and session-start match any prefix; verified on a custom-prefix scratch board
- [x] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #3 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: replaced all four hardcoded 'task-[0-9]+' greps (stop-gate Gate 2 count; session-start In Progress extraction + both parked listings) with start-of-line anchored '^[[:space:]]*[A-Za-z]+-[0-9]+', matching any prefix while avoiding id-shaped words inside titles. Verification: on the AP-prefix scratch board Gate 2 blocked counting 1 In Progress task, session-start resolved AP-2 in full and listed AP-1 under Blocked; regression on this repo's task- board confirmed (TASK-8 listed). Repo gate green. No README change (internal behavior, no user-facing contract change).
<!-- SECTION:NOTES:END -->
