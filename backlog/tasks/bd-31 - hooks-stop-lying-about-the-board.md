---
id: BD-31
title: hooks stop lying about the board
status: Review
assignee: []
created_date: '2026-08-25 05:52'
updated_date: '2026-08-25 07:16'
labels: []
dependencies: []
ordinal: 20000
---

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
COMMITMENT COMPLETE 2026-08-25. BD-20, BD-21, BD-22 and BD-24 all closed, 21 acceptance criteria checked across the four, each with its own evidence note.

BD-31 carries no acceptance criteria of its own and none were added. Its acceptance IS the union of its subtasks', and minting retrospective criteria on the parent would be exactly the decay pattern documented in the decision doc written for BD-21 this session. Verification happened once, on the batch, which is the point of the commitment rule.

VERIFICATION against the final tree, every suite re-run after the last edit rather than cited from earlier in the session: bd31 38, bd25 60, bd19 29, bd18 27, pairing 29. 183 assertions green across five suites. Repo gate GREEN.

THE BUNDLE WAS THE RIGHT UNIT. Three of the four edit session-start.sh and two also edit lib/board.sh. Worked sequentially each would have landed in Review with evidence the next one invalidated. The one shared file that made this necessary, board_summary, ended up carrying BOTH the dependency marking and the terminal cap in a single awk pass; splitting them across two tickets would have meant writing that function twice.

TWO REGRESSIONS CAUGHT, both in older suites, both from one intentional change. The footer said ONE ACTIVE TASK while the contract shipped in BD-25 said ONE ACTIVE COMMITMENT. Aligning the footer broke two assertions that were pinning the old wording. Worth recording that the inconsistency was mine, introduced in BD-25 by changing the contract and not the hook that repeats it, and that it survived a full green suite at the time because nothing asserted the two agreed.

FOUND AND NOT FIXED, recorded on BD-20: committing busts the green cache even when the working tree is byte-identical, because HEAD moves and the diff empties. Guaranteed miss on every commit turn. Fixing it means hashing the full tracked tree on every stop to save an occasional run, which is the wrong trade. Documented in the README.

WALTER BLOCKED ITS OWN WORK FOUR MORE TIMES this session, all string-matching false positives, all failing safe: the quoted-prose one twice, the subtask matcher once, and the copy-out-of-the-board-directory one once. Two of those are now fixed. The pattern is that this repo writes prose and tooling ABOUT the guards constantly, so it eats them at a rate no consumer repo would.
<!-- SECTION:NOTES:END -->
