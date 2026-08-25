---
id: BD-33
title: 'stop-gate: content_hash breaks fail-open on macOS system bash'
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
labels: []
dependencies: []
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Regression introduced by BD-20 on 2026-08-25. content_hash builds an EXCLUDES array only when board_hash_exclude_pathspec is available. When hooks/scripts/lib/board.sh fails to load, EXCLUDES stays empty and the script expands it under 'set -u'. Verified directly: /bin/bash 3.2.57 (the macOS system bash) aborts with 'A[@]: unbound variable' on an empty array expansion under nounset, while homebrew bash 5.3 does not. The failure lands exactly on the fail-open path that the repo's stated invariant says must never break a session. It passed all 183 scratch assertions because every suite ran under homebrew bash. Fix is to guard the expansion; the wider lesson is that the suites prove nothing about the interpreter walter will actually meet on a stock Mac.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->
