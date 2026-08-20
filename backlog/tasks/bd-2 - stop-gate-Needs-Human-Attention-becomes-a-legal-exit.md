---
id: BD-2
title: 'stop-gate: Needs Human Attention becomes a legal exit'
status: Done
assignee: []
created_date: '2026-08-20 10:38'
updated_date: '2026-08-20 10:50'
labels:
  - stop-gate
dependencies: []
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The land-the-plane block (Gate 2) currently offers finish/blocked/follow-up. Add the honest 4th exit: note what you need from the human, move the task to Needs Human Attention. Read blocked_status and human_attention_status from .board/config.json. Rationale (session 2026-08-20): In Progress must strictly mean 'agent actively executing'; the cheapest legal exit from the gate must be truthful, or the gate trains fake-promotion to Review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 stop-gate.sh Gate 2 message lists the Needs Human Attention exit and reads status names from config
- [x] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #3 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: Gate 2 block message now offers 4 exits (Review / Blocked / Needs Human Attention / follow-up task) and reads blocked_status + human_attention_status from config with jq // defaults — so already-onboarded repos need NO config.json migration when using default names (kills requirement 2 of task-6). Verification, scratch repo E2E: (a) empty config.json + task In Progress → block fires with default names; (b) custom names in config → message uses them; (c) task moved to Needs Human Attention → gate passes exit 0. Repo gate (bash -n + jq) green. README enforcement table row updated.
<!-- SECTION:NOTES:END -->
