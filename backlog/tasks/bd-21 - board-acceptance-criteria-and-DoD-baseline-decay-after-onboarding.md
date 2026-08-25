---
id: BD-21
title: 'board: acceptance criteria and DoD baseline decay after onboarding'
status: To Do
assignee: []
created_date: '2026-08-23 02:18'
updated_date: '2026-08-25 05:46'
labels: []
dependencies: []
ordinal: 10000
parent_task_id: BD-31
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
- [ ] #1 dod_baseline is either enforced, surfaced, or removed - not inert
- [ ] #2 Decision recorded on whether criteria must predate the In Progress transition
- [ ] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #4 README updated if behavior changed
<!-- AC:END -->
