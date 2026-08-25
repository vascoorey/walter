---
id: BD-16
title: >-
  dogfood review: analyse walter usage in Riots-Vasco and ShannonAndTheRiots
  transcripts
status: Review
assignee: []
created_date: '2026-08-23 02:03'
updated_date: '2026-08-23 02:18'
labels: []
dependencies: []
ordinal: 5000
---

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Latest transcripts from both repos analysed by dedicated agents
- [x] #2 Findings triaged into board tasks, not a loose doc
- [ ] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DONE 2026-08-23. Two Opus agents read six transcripts across the two repos (Riots-Vasco: 05267351, 6c5a66b9, 0bd65664 plus fcc4b76c and 01d736b6 reached by the agent; ShannonAndTheRiots: b4455122, facbbae5, 801e6415). Both briefed read-only and told not to manufacture findings.

EVIDENCE OF HEALTH: 6 stop-gate blocks across all sessions, every one a true positive, agent recovered correctly 6/6 with a substantive note each time and never routed around one. Zero PreToolUse denials in ShannonAndTheRiots across ~40 board calls carrying long prose payloads with column names in them - the README's admitted quoted-prose false-positive class never fired. guard-task-files.sh never fired in five Riots-Vasco sessions. Fail-open confirmed real: pre-onboarding sessions exited in 21-52ms and injected nothing. Zero human complaints, corrections, or workarounds aimed at the board across ~60 human turns; when the tool got in the way the human extended it rather than disabled it. Contract-only rules (claim gate, triage protocol) were followed voluntarily, including two unprompted AskUserQuestion pauses reminding the human that promotion was theirs.

PAIRING VALIDATED WITH BEFORE/AFTER IN ONE CONVERSATION: Riots-Vasco fcc4b76c, 5 land-the-plane blocks and 10 wasted board writes in 30 minutes of pure conversation; human added the column mid-session via /walter:onboard; the following 30 minutes and 6 turns produced zero blocks and zero status writes. ShannonAndTheRiots, lacking the column, showed 7 round-trips in one session, 14 of 40 board calls being round-trip overhead.

FINDINGS TRIAGED: BD-18 (read-only queries blocked - plain bug), BD-19 (hooks offer columns the repo lacks), BD-20 (board writes bust the green cache), BD-21 (AC and dod_baseline decay), BD-22 (dependency-blocked To Do rendered pullable), BD-23 (no route out of Triage when the human names the task), BD-24 (five papercuts).

NOT TICKETED, deliberately: the ShannonAndTheRiots agent recommended adding a /walter:upgrade command based on a hand-rolled sed of config.yml. That upgrade happened 2026-08-20, before BD-6 shipped the upgrade path; the Riots-Vasco agent independently observed /walter:onboard's upgrade path working live mid-session on 08-21. Already fixed.

AC-3 and AC-4 (scratch-repo verification, README) are not applicable: this task produced analysis and Triage tickets, no behaviour change. Verification is the tickets themselves, each carrying its own evidence.
<!-- SECTION:NOTES:END -->
