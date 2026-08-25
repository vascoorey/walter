---
id: BD-33
title: 'stop-gate: content_hash breaks fail-open on macOS system bash'
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
updated_date: '2026-08-25 10:21'
labels: []
dependencies: []
parent_task_id: BD-37
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Regression introduced by BD-20 on 2026-08-25. content_hash builds an EXCLUDES array only when board_hash_exclude_pathspec is available. When hooks/scripts/lib/board.sh fails to load, EXCLUDES stays empty and the script expands it under 'set -u'. Verified directly: /bin/bash 3.2.57 (the macOS system bash) aborts with 'A[@]: unbound variable' on an empty array expansion under nounset, while homebrew bash 5.3 does not. The failure lands exactly on the fail-open path that the repo's stated invariant says must never break a session. It passed all 183 scratch assertions because every suite ran under homebrew bash. Fix is to guard the expansion; the wider lesson is that the suites prove nothing about the interpreter walter will actually meet on a stock Mac.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #2 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
FIXED, and the ticket's stated severity was wrong. Correcting it here rather than leaving the overstatement on the board.

What was claimed: that the empty-array expansion aborted content_hash and broke the fail-open guarantee. What actually happens, measured: under /bin/bash 3.2.57 with hooks/scripts/lib/board.sh absent, both git calls in content_hash fail with 'EXCLUDES[@]: unbound variable' on stderr, content_hash yields an empty hash, and the '[ -z $HASH ]' branch then forces a full verification run. The hook exits 0 and the gate still fires on changed code, proven behaviourally: the test command ran once on the first stop and again after editing a file. So this was never a safety hole. It is a silent reversal of the BD-20 cache win plus stderr noise, on stock macOS only.

Fix: both expansions in stop-gate.sh content_hash now use the 3.2-safe ${EXCLUDES[@]+"${EXCLUDES[@]}"} form, with a comment saying why so it does not get 'simplified' back.

Evidence. New suite scratchpad/bd33-e2e.sh, 17 assertions, all green, and it pins the interpreter to /bin/bash rather than PATH bash: the lib-missing path exits 0 with no nounset abort and no bad substitution; the cache still hits on an unchanged tree and still busts on a real code change under 3.2; all four hook entry points and parent.sh run clean under 3.2. Confirmed sensitive by reverting the fix in a copy, which reproduces the unbound-variable errors.

Root cause worth keeping: 183 assertions passed while this was broken because every suite invoked hooks through PATH bash, which is homebrew 5.3 here. One interpreter proves nothing about the one macOS actually ships. README sharp edges now says so.
<!-- SECTION:NOTES:END -->
