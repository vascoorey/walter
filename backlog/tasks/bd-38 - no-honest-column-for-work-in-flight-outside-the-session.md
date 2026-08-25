---
id: BD-38
title: no honest column for work in flight outside the session
status: Triage
assignee: []
created_date: '2026-08-25 10:25'
updated_date: '2026-08-25 10:31'
labels: []
dependencies: []
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered while working BD-37 on 2026-08-25. The stop-gate fired twice in one session on a state the board cannot express: the agent has launched a long-running process outside the session (a detached analysis, a background build, a remote job) and is legitimately waiting on it. In Progress is dishonest because nothing is executing in the session and the contract says In Progress never survives a stop. Meatbag is dishonest because nothing is needed from the human. Blocked is the closest fit and is what BD-37 was parked as, but the column means external impediment, and a job you started yourself and expect to succeed is not an impediment. Using Blocked for it makes the column mean two different things, which is how a status stops carrying information.

This is the pattern the repo's own guidance calls out: recurring friction is usually a missing state rather than a badly tuned rule. It fired twice in one session, and it will fire every time an agent hands work to a subagent, a workflow, or CI.

Worth settling before adding a column: whether this is a real state or whether Blocked should simply be redefined to mean 'waiting on something outside this session, mine or not', which costs nothing and is a doc change. The cheaper answer is probably the right one, and adding a column that duplicates Blocked would be exactly the redundant friction the repo warns about.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
PREMISE LARGELY WRONG. Recording before anyone builds it.

This was filed claiming the board cannot express 'waiting on work in flight outside the session'. It can. stop-gate.sh:124-131 already emits a Pairing nudge on every land-the-plane block where the board has a Pairing column, and that nudge fired on the stop that produced this ticket. The failure was the agent's categorisation, not a missing state: it asked what it was waiting ON (an external process, therefore Blocked) instead of what the work WAS (a genuine back-and-forth with the human, therefore a Pairing recommendation).

The widening this ticket proposed, redefining Blocked to mean 'waiting on anything outside this session', is actively worse and should not be built. Blocked is agent-settable, so an async-executing sense would be a legal exit the agent can grant itself by asserting it, which is the failure mode the Pairing and subtask denials exist to prevent. Routing to Pairing instead cannot be self-granted because entry is human-only.

Two things left genuinely open, neither urgent:
1. Whether Pairing absorbing long-running waits erodes it, since it survives stops and the gate does not police it. Human-only entry is the only thing holding that line. Watch whether Pairing starts accumulating parked work rather than active collaboration.
2. The autonomous case, where an agent waits on CI or a long job with no human present, has no pairing partner and is not covered. Speculative for walter today, which is used interactively. Do not build for it until it happens.

Close this unless someone wants to pursue (1) or (2).
<!-- SECTION:NOTES:END -->
