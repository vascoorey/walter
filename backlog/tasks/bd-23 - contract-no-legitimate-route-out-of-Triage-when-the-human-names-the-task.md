---
id: BD-23
title: 'contract: no legitimate route out of Triage when the human names the task'
status: Triage
assignee: []
created_date: '2026-08-23 02:18'
labels: []
dependencies: []
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The contract says never pull from Triage, and in some repos additionally to ask before claiming. Real usage does not match.

ShannonAndTheRiots 2026-08-22: the human wrote 'let's pick up rm-8'. The agent moved RM-8 straight from Triage to In Progress, breaking the letter of the rule rather than refusing a direct instruction. It had no third option.

Broader pattern in the same session: 7 of 8 tasks were created and claimed in one shell command, and the three tasks seeded into To Do at onboarding have never been touched. In practice the board is a ledger of what the human just asked for, not a queue the agent pulls from.

Counter-evidence that the rule is not dead weight: in Riots-Vasco the agent twice paused with AskUserQuestion to remind the human that promotion was theirs ('RIOTS-20 is still in Triage - promoting it is your move, not mine'), with NO hook behind that rule. The rule is doing real work when the agent is choosing; it only breaks when the human has already chosen.

Decide whether 'the human named this task in this turn' counts as an explicit promotion, and write it down either way. Contract-level, no hook needed.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Contract states what happens when the human names a Triage task directly
- [ ] #2 Template and CLAUDE.md agree
- [ ] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #4 README updated if behavior changed
<!-- AC:END -->
