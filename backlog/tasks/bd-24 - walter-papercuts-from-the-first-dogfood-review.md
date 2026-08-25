---
id: BD-24
title: walter papercuts from the first dogfood review
status: To Do
assignee: []
created_date: '2026-08-23 02:18'
updated_date: '2026-08-25 07:15'
labels: []
dependencies: []
parent_task_id: BD-31
ordinal: 13000
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
- [x] #1 Migration script ships executable
- [x] #2 Task-file denial names the human handoff route
- [x] #3 Footer and repo claim-gate config no longer contradict
- [x] #4 Terminal-column rendering is capped
- [x] #5 Block-counter reset semantics confirmed or changed deliberately
- [x] #6 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #7 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DONE 2026-08-25 under BD-31. All seven items closed.

1. onboard.md now tells the interviewer to make the migration script executable, and says why: it has already cost a human three failed attempts.

2. Both task-file denials, the Write/Edit one and the shell-side one, now name the sanctioned route: write the script outside the board directory, make it executable, hand it to the human to run with the bang prefix. The agent no longer has to invent that recovery.

3. The footer contradiction is gone, and this needed more than wording. There was NO claim-gate key at all: onboard told the interviewer to add a handling note and named no key, and no hook read one. Added claim_gate as a real boolean in the config, written by onboard from the interview answer and read by session-start, which now either tells the agent to pull work or tells it to ask, never both. onboard also records why the gated status list is the wrong home for this: putting the active status there fires a denial whose text tells the agent to move to Review instead, which is nonsense here, and it would stop the agent claiming anything at all.

4. The terminal column caps at 10 and states how many it omitted. Silent truncation would have been its own lie. Every other column renders in full. The cap is a named constant in the lib.

5. Block-counter reset CONFIRMED, not changed. Per-stop reset is correct: the cap exists to break a single stuck stop, and a session-long counter would disarm the gate for legitimate later work. The five-blocks-in-one-session observation is the design working, not failing. Documented in the README sharp edges so it reads as intended rather than broken.

6. Fixed. For a copy or move only the DESTINATION is a write, and the destination is the last token of the segment, so reading files out of the board directory is allowed while writing into it stays blocked. Verified by a 13-case probe covering both directions plus redirect, tee, in-place edit and remove. Known residual, now documented: a copy into the directory with a trailing redirect puts a non-path token last and slips through.

7. Confirmed accurate and closed. The narrowing landed while shipping BD-25 and is covered by four assertions there.

Verification: 12 assertions in bd31-e2e for items 1 through 4 and 6, plus the 13-case probe, plus the four BD-25 assertions for item 7. Item 5 changed no code.
<!-- SECTION:NOTES:END -->
