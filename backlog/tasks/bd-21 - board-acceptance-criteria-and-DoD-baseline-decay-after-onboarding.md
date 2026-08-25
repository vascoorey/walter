---
id: BD-21
title: 'board: acceptance criteria and DoD baseline decay after onboarding'
status: Review
assignee: []
created_date: '2026-08-23 02:18'
updated_date: '2026-08-25 11:31'
labels: []
dependencies: []
parent_task_id: BD-31
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two related decays found in Riots-Vasco 2026-08-23.

(a) dod_baseline in .board/config.json is read by NO hook and never appears in the SessionStart injection. 14 of 38 task files carry the baseline items and all 14 are from onboarding day; every task created since carries neither, despite the repo CLAUDE.md stating they are seeded as acceptance criteria on every task. The config field is currently decoration.

(b) Acceptance criteria are frequently authored AFTER the work and checked off in one blast immediately before the Review transition (RIOTS-25, 20, 35, 36, 37, 38 all show the pattern). That satisfies the Review gate without the criteria ever having constrained anything.

Counter-evidence, which is why this is a papercut and not a hole: tasks created during deliberate planning carry substantial criteria written before any work, and RIOTS-36 was honestly reopened from Review with three new criteria when an upstream skill changed. The rule holds when a task is planned and decays when a task is minted reactively mid-work. Review notes carry genuine evidence either way, so the loss is small.

Decide: seed dod_baseline at task creation, surface it in the SessionStart footer, or drop the field. Separately, decide whether criteria must exist before a task leaves To Do.

Found by BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 dod_baseline is either enforced, surfaced, or removed - not inert
- [x] #2 Decision recorded on whether criteria must predate the In Progress transition
- [x] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DONE 2026-08-25 under BD-31. Both decisions taken with the human.

(a) SURFACED, not enforced and not removed. session-start.sh reads dod_baseline and emits it in the Board rules footer, beside the discovered-work rule, which is where the agent is about to create tasks. An empty array emits nothing, so repos that declined a baseline see no noise. The field is now live and the contract's claim that the baseline is seeded onto every task is true by surfacing rather than false by assertion.

Enforcement was rejected: a creation gate can only check that criteria exist, and its cheapest legal exit is one throwaway criterion per task. That would make the board look healthier than it is, which is worse than the honest decay we can currently measure.

(b) NO GATE on criteria predating the active transition. Recorded in backlog/decisions/2026-08-25-acceptance-criteria-timing.md, because a rejected gate leaves no trace in code. The argument: a gate can check presence but never that the criteria constrained anything, and criteria authored to pass a claim gate are written in the same breath as the claim by the same agent with the work already decided.

The decision doc also records what this deliberately leaves unsolved. The late-criteria pattern is real; it is a planning problem, not a gate problem, and making reactive Triage capture expensive would push discovered work back into the chat where it vanishes entirely. It names the measurement that would reverse the decision: criteria appearing late on PLANNED tasks, which would mean the decay had spread past reactive capture.

Verification: 6 assertions in bd31-e2e covering a populated baseline appearing in full, each item listed, the instruction to pass them at creation, and an empty baseline emitting nothing while the rest of the footer is unaffected.
<!-- SECTION:NOTES:END -->
