---
id: BD-20
title: 'stop-gate: board writes bust the Gate 1 green cache'
status: To Do
assignee: []
created_date: '2026-08-23 02:17'
updated_date: '2026-08-25 05:46'
labels: []
dependencies: []
ordinal: 9000
parent_task_id: BD-31
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The Gate 1 content hash includes 'git diff HEAD', and backlog/tasks/*.md is git-tracked, so writing a task note invalidates the cache and the next stop pays a full verification run.

Measured in ShannonAndTheRiots 2026-08-22: three consecutive turns that touched ONLY the board cost ~2.7s each, roughly 8s total, against a 321-468ms cache hit. Board ceremony paying test latency is exactly backwards.

Fix: exclude the board's task directory from the content hash. Caveat from the same analysis: two cache misses on read-only and pure-text turns were unexplained. Reproduce those before assuming the exclusion is the whole story.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A turn that only mutates the board hits the green cache
- [ ] #2 A turn that changes real code still busts it
- [ ] #3 The two unexplained misses are reproduced or ruled out
- [ ] #4 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #5 README updated if behavior changed
<!-- AC:END -->
