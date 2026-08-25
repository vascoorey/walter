---
id: BD-24
title: walter papercuts from the first dogfood review
status: To Do
assignee: []
created_date: '2026-08-23 02:18'
updated_date: '2026-08-25 05:50'
labels: []
dependencies: []
ordinal: 13000
parent_task_id: BD-31
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Five one-liners found across Riots-Vasco and ShannonAndTheRiots, 2026-08-19 to 08-23. Small enough to batch, real enough to not lose.

1. onboard.md writes .board/migrate-prefix.sh without making it executable. The human hit 'permission denied', then had to work out the sh invocation themselves (ShannonAndTheRiots 2026-08-22, three consecutive attempts).

2. The task-file write denial should name the bang-prefix human handoff as the sanctioned route for the one migration the CLI cannot do. The agent had to invent that recovery itself in Riots-Vasco; it did so well, but should not have to.

3. The SessionStart footer says 'Pull ONE task from To Do, set it In Progress before touching code' while Riots-Vasco's own config declares a contract-level claim gate saying to ask first. The two contradict; the agent correctly followed the config. Consider deriving the footer line from the repo config.

4. The injection renders every task in the terminal column. 2.8KB at 5 of them; that board now has 12 and it only grows. Cap the list before it becomes a real cost. No complaint yet.

5. The stop-gate block counter is deleted on every clean stop, so five blocks accrued in one Riots-Vasco session without ever tripping the cap of 3. Confirm that is intended; the cap protects against a single stuck stop, not against a session-long treadmill.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Migration script ships executable
- [ ] #2 Task-file denial names the human handoff route
- [ ] #3 Footer and repo claim-gate config no longer contradict
- [ ] #4 Terminal-column rendering is capped
- [ ] #5 Block-counter reset semantics confirmed or changed deliberately
- [ ] #6 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #7 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
UPDATE 2026-08-25: item 7 above is now NARROWED, not open. The subtask denial originally checked the create subcommand and the parent flag as two independent matches across the whole command, so any unrelated short flag of that letter anywhere in the command was enough. A directory-making command beside a plain task creation tripped it. It now requires both in the same command segment, one regex rather than two, and four assertions in the BD-25 suite cover that regression. What remains is the narrow residual shared with every other guard here: one segment carrying both a creation and an unrelated flag of that letter.

Items 1 through 6 and the earlier quoted-prose note are unchanged and still open. The quoted-prose one fired twice more while landing BD-25, once on a note describing the guards and once on a documentation edit that merely quoted the denied example. It is the highest-frequency papercut on this list by a wide margin.
<!-- SECTION:NOTES:END -->
