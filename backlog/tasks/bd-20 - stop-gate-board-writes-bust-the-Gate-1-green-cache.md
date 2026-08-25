---
id: BD-20
title: 'stop-gate: board writes bust the Gate 1 green cache'
status: To Do
assignee: []
created_date: '2026-08-23 02:17'
updated_date: '2026-08-25 07:15'
labels: []
dependencies: []
parent_task_id: BD-31
ordinal: 9000
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
- [x] #1 A turn that only mutates the board hits the green cache
- [x] #2 A turn that changes real code still busts it
- [x] #3 The two unexplained misses are reproduced or ruled out
- [x] #4 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #5 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DONE 2026-08-25 under BD-31.

Fix: the green-cache content hash now excludes backlog/tasks/ and backlog/archive/ via git pathspec, in both the tracked diff and the untracked listing. The pathspec comes from board_hash_exclude_pathspec in lib/board.sh so BD-11 stays mechanical. backlog/decisions/ is deliberately NOT excluded: it is authored prose rather than board state, and one extra run when a decision doc changes is rare and cheap. That asymmetry is commented in the code so it does not read as an oversight.

AC 3, the two unexplained misses. Both RULED OUT and REPRODUCED respectively.

RULED OUT, the theory the ticket proposed: read-only board commands do not change the hash. Probed directly against a scratch board, running the list, show and board subcommands between two hash computations. Byte-identical every time. The ticket's stated suspicion was wrong.

REPRODUCED, a cause the ticket did not consider: COMMITTING busts the cache even when the working tree is byte-identical. HEAD moves and the diff empties, so the hash changes though nothing testable did. Demonstrated with a scratch repo where the file shasum was identical across the commit boundary and the content hash still changed. This is a guaranteed miss on every commit turn, and a turn described as pure-text in the original analysis could easily have included one.

DELIBERATELY NOT FIXED. Making the hash commit-invariant means hashing the full tracked tree rather than HEAD plus diff, which taxes every stop including cache hits, measured at 321 to 468ms, to save an occasional run on a turn that usually accompanied a real change anyway. Wrong trade. Documented in the README instead.

Verification: 7 assertions in bd31-e2e covering cache hit on an unchanged tree, hit after writing a task note, hit after creating a task, bust on a code edit, re-stamp, and bust on a new untracked source file. Detection is a side-effecting verification command counting its own runs, not an inference from timing.
<!-- SECTION:NOTES:END -->
