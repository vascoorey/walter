---
id: BD-15
title: 'board: add a human-only ''Pairing'' column for multi-turn work'
status: Done
assignee: []
created_date: '2026-08-21 10:21'
updated_date: '2026-08-23 01:54'
labels: []
dependencies: []
ordinal: 0.48828125
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Requested 2026-08-21. Problem: a task that is genuinely a back-and-forth with the human (BD-10 'pick a better name', BD-12 'rename the column') has no honest home. In Progress never survives a stop, so every turn costs a park-to-parked-column and a move-back, which is the tedium. Needs Attention is wrong because nobody is waiting; both parties are engaged.

Solution: a new column, default name 'Pairing', that sits beside In Progress as a second ACTIVE state and legitimately survives a stop. Decided 2026-08-21: the agent MAY change code while a task sits there (BD-10 and BD-12 both started as discussion and ended in commits; a handoff back to In Progress mid-thread would re-add the ceremony). Safe because ENTRY IS HUMAN-ONLY: the agent cannot put a task there, so it cannot use the column to dodge the land-the-plane gate. The agent MAY recommend it (note on the task plus say so in chat) when work is devolving into multi-turn human collaboration; the human decides.

Mechanism: guard-transitions blocks setting pairing_status with its own denial text (distinct from the Done gate, which says 'move to Review instead' and would be wrong guidance here). Stop-gate Gate 2 counts In Progress only, so Pairing tasks are already ignored; its block message gains a line teaching the recommendation path. Session-start surfaces Pairing tasks in full detail as active work. Focus rule becomes: at most one active task total across In Progress and Pairing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 New status 'Pairing' exists in the onboard target column set, positioned directly after In Progress, with documented semantics distinguishing it from Blocked and from the human-attention column
- [x] #2 guard-transitions blocks the agent from setting pairing_status, with denial text that names the recommendation path rather than the Review-instead text used for the Done gate
- [x] #3 Stop-gate does not count Pairing tasks as dangling, and its land-the-plane message teaches the agent to recommend Pairing when a task is becoming multi-turn work
- [x] #4 Session-start renders Pairing tasks in full detail as active work, and no longer tells the agent to pull new work when a Pairing task is open
- [x] #5 Config key pairing_status defaults to 'Pairing' via jq so already-onboarded repos need no config edit beyond adding the column
- [x] #6 CLAUDE.md contract template and onboard upgrade check cover the new column
- [x] #7 Decision doc records why entry is human-only and why code changes are allowed
- [x] #8 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #9 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Shipped the Pairing column as a second ACTIVE state sitting directly after In Progress.

Hooks. guard-transitions.sh gained a dedicated check for pairing_status, deliberately separate from human_gated_statuses: that list is the Review-to-Done end gate and its denial text ('move to Review instead') would be wrong guidance here. The new denial names the column as human-only, teaches the recommendation path (note it on the task, say so, park and stop), and names the fallback column. Moving a task OUT of Pairing stays unrestricted. stop-gate.sh Gate 2 still counts In Progress only, so Pairing tasks are ignored by construction; its block message gained a closing line teaching the recommendation and stating the agent may not set the column itself. session-start.sh now renders In Progress and Pairing as two independent sections, both in full task detail, and the pull-new-work nudge only appears when neither has anything. Focus rule in the rules footer became one active task counting both columns.

Config. pairing_status defaults to Pairing through the same jq fallback used by the other column names, so already-onboarded repos need no config edit, only the column added to backlog/config.yml. Verified that a custom override is honoured and that the default name stops being gated once overridden.

Docs. onboard.md target column set, semantics paragraph, upgrade check, and config template all updated. CLAUDE.md template and this repo's own contract gained the Pairing rule; this repo's contract was also missing the 'In Progress never survives a stop' line, now restored. README gained an enforcement-table row, a board-diagram entry, and a bullet. Decision doc at backlog/decisions/2026-08-21-pairing-column.md records why human-only entry is the load-bearing property: every other attribute of this column relaxes the stop-gate, so without a human owning the door the cheapest legal exit becomes 'declare it a conversation'.

This repo's board gained the column too, positioned between In Progress and Blocked.

VERIFICATION. Gate green. Two end-to-end suites against throwaway repos, 63 assertions, 63 pass, 0 fail. scratchpad/pairing-e2e.sh (29) covers: human placing a task in the column via the CLI; agent blocked from entering it through both flag spellings; denial text asserted to contain the recommendation path AND asserted NOT to contain the Done-gate text; agent still able to exit to Review and to Blocked; Done gate unaffected and keeping its own text; a Pairing task alone producing no stop block; In Progress still blocking with the Pairing task excluded from the count; both new lines present in the block message; session-start rendering the section, the full task detail, the work-in-place instruction, the focus rule and the footer; a lone Pairing task suppressing the pull-new-work nudge and the empty In Progress header; the nudge returning on an empty board; a custom column name being gated instead of the default. scratchpad/lib-e2e.sh (34) re-run unchanged as a regression check, and doubles as the backwards-compatibility case since that scratch repo has no Pairing column at all.
<!-- SECTION:NOTES:END -->
