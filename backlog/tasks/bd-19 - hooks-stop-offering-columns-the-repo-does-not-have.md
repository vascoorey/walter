---
id: BD-19
title: 'hooks: stop offering columns the repo does not have'
status: Review
assignee: []
created_date: '2026-08-23 02:17'
updated_date: '2026-08-23 08:16'
labels: []
dependencies: []
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
session-start.sh and stop-gate.sh read pairing_status / blocked_status / human_attention_status from .board/config.json with jq defaults, and never check that the column exists in the repo's backlog/config.yml status list.

Observed in ShannonAndTheRiots 2026-08-20 to 08-23: the SessionStart rules footer and every land-the-plane block instructed the agent to recommend 'Pairing' in a repo whose status list had no such column. Dead advice in every block, for three days. The same hole applies to Blocked and Needs Attention: the stop-gate can offer the agent exits the CLI would reject.

Fix: read the repo's real status list and suppress any mention of a column that is absent. Fail-open still applies: if config.yml is unreadable or unparseable, keep current behaviour rather than dropping the guidance.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 No hook mentions a column absent from the repo's status list
- [x] #2 Exits offered by the stop-gate are all settable via the CLI in that repo
- [x] #3 Unreadable config.yml falls back to current behaviour, no session breakage
- [x] #4 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #5 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DONE 2026-08-23. Root cause: session-start.sh and stop-gate.sh read column names from .board/config.json with jq defaults and never checked the board had them. ShannonAndTheRiots was told for three days to recommend a column that did not exist.

FIX: lib/board.sh gains board_statuses() (memoised, parses 'backlog config get statuses', comma-separated in 1.50.1) and board_has_status(), which returns TRUE on an empty or unreadable list so a CLI change cannot silently strip guidance. session-start.sh builds its exit list, land-the-plane line and focus rule from the columns present. stop-gate.sh builds its options list the same way and now references options BY NAME, never by number, so a missing column cannot leave a dangling 'take option 3'.

DELIBERATELY NOT CHANGED: guard-transitions.sh. It runs on every Bash tool call under a 10s timeout and currently does zero I/O; adding a CLI call there would be a real regression. It also never advertises a column, it only reacts to an attempt to set one. The constraint is written into the board_has_status comment so a later change does not quietly break it.

VERIFICATION: new suite scratchpad/bd19-e2e.sh, 29/29 green, across four boards. Full board (regression, all mentions intact, four options). No-Pairing board, the ShannonAndTheRiots shape: the string does not appear anywhere in session-start or the stop-gate block, focus rule drops its clause, surviving columns unaffected. Minimal v0.1 five-column board: no parked-column guidance at all, options renumber to two, closer drops the always-legal claim, and no dangling option number. Unreadable status list: every mention kept, and board_has_status probed directly to confirm it defaults to present. Plus an exact-match probe proving 'In Review' does not match 'Review' and matching is case-insensitive.

REGRESSION: bd18-e2e 27/27, lib-e2e 34/34, pairing-e2e 29/29, all re-run after this change. 119 assertions green in total. Verification gate green.

README: the onboarding upgrade paragraph now states that hooks adapt to the board's real column set until the upgrade is run.
<!-- SECTION:NOTES:END -->
