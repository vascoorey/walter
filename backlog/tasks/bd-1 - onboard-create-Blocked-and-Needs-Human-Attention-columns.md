---
id: BD-1
title: 'onboard: create Blocked and Needs Human Attention columns'
status: Done
assignee: []
created_date: '2026-08-20 10:38'
updated_date: '2026-08-20 10:48'
labels:
  - onboard
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update commands/onboard.md: target status set becomes Triage, To Do, In Progress, Blocked, Needs Human Attention, Review, Done; config.json template gains blocked_status and human_attention_status keys. Semantics: Blocked = external impediment; Needs Human Attention = ball in the human's court. This repo's own board (done during its onboarding) is the reference.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 onboard.md Step 2 status set and Step 4 config template updated
- [x] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #3 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: onboard.md Step 2 now targets 7 columns with Blocked/NHA semantics spelled out; Step 4 config template gains blocked_status + human_attention_status (this repo's .board/config.json already matches). README board-shape section updated with the parked states and return-path rule. Verification: scratch-repo E2E in session scratchpad — backlog init 1.50.1 + statuses sed, then 'backlog task create -s "Needs Human Attention"' and 'edit -s Blocked' both accepted, task listed under Blocked. Repo gate (bash -n + jq) green.
<!-- SECTION:NOTES:END -->
