---
id: BD-5
title: 'stop-gate: /tmp counter hygiene'
status: Done
assignee: []
created_date: '2026-08-20 10:38'
updated_date: '2026-08-20 11:14'
labels:
  - stop-gate
dependencies: []
ordinal: 31.25
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Counter files /tmp/board-discipline-stop-<session_id> are never cleaned up and do not survive session-id changes on resume/compaction. Age them out and consider a repo-scoped key. Small; discovered during 2026-08-20 friction review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Stale counter files cleaned up; behavior across session resume documented
- [x] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #3 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: stop-gate.sh now prunes /tmp/board-discipline-* files older than 7 days on every run (counters + green stamps), with the macOS gotcha handled — /tmp is a symlink and find needs the trailing slash to traverse the start point (first E2E run caught exactly this: stale file survived; fixed, re-verified). Session-resume behavior documented in code + README: counter is per-session by definition, an id change re-arms a capped gate, deliberate. E2E in scratch: 19-day-old file pruned, fresh file kept, gate still passes green. Repo gate green.
<!-- SECTION:NOTES:END -->
