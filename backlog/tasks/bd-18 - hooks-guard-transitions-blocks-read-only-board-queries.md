---
id: BD-18
title: 'hooks: guard-transitions blocks read-only board queries'
status: Review
assignee: []
created_date: '2026-08-23 02:17'
updated_date: '2026-08-23 08:12'
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
DONE 2026-08-23. Root cause: board_cmd_touches_status in hooks/scripts/lib/board.sh required only the string 'backlog' plus a status flag, so a read-only filter was indistinguishable from a transition. Fix: also require a mutating subcommand, matched as <tool> (task|tasks) (edit|create). Tool name still comes from BOARD_TOOL so BD-11 stays mechanical.

VERIFICATION: new suite scratchpad/bd18-e2e.sh, 27/27 green. Covers read-only passes (task list with the short flag, the long flag, the equals form, two filters at once, board with a status filter, and the pairing column) including the exact compound command observed being blocked in Riots-Vasco on 2026-08-23, verbatim from the transcript; mutating blocks retained (task edit and task create, all three flag spellings, quoted value, the 'tasks' alias, and a command prefixed by 'cd sub &&'); denial texts for both the gated and pairing paths asserted intact; non-gated and parking transitions still allowed; task-file write and rogue TODO.md guards unaffected; fail-open with no .board/config.json.

REGRESSION: lib-e2e.sh 34/34 and pairing-e2e.sh 29/29 re-run unchanged. Verification gate green (bash -n across hooks/scripts and lib, jq parse of all three json manifests).

RESIDUAL, documented not fixed: one command line that mixes a read-only status filter with an unrelated edit still blocks. Asserted in the suite so it stays a known quantity. Fixing it needs a shell parser, which the guards deliberately are not. README's sharp-edges bullet now names both false-positive classes and states read-only queries are exempt.

FIELD NOTE: the OTHER known false positive, a gated status name inside quoted prose on a task edit, fired against this very command on the first attempt at writing these notes - the note described the residual using a literal example and was blocked. The ShannonAndTheRiots dogfood analysis reported that class never firing across roughly 40 board calls; it fires reliably as soon as the prose is ABOUT the board. Worth folding into BD-24 or a ticket of its own.
<!-- SECTION:NOTES:END -->
