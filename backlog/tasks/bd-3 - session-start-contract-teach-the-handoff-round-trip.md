---
id: BD-3
title: 'session-start + contract: teach the handoff round-trip'
status: Done
assignee: []
created_date: '2026-08-20 10:38'
updated_date: '2026-08-20 10:52'
labels:
  - session-start
dependencies: []
ordinal: 250
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
session-start.sh: surface Blocked and Needs Human Attention tasks with the rule 'resuming one? move it back to In Progress before touching code' — without this, tasks rot in the handoff column while the agent works and the stop-gate goes blind. templates/claude-md-section.md: add the Blocked vs Needs Human Attention semantics (see this repo's CLAUDE.md for the reference wording).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 session-start.sh lists Blocked and Needs Human Attention tasks with return-path guidance
- [x] #2 claude-md-section.md template carries both statuses and their semantics
- [x] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: session-start.sh reads blocked_status/human_attention_status with jq // defaults and injects two new sections — Needs Human Attention tasks with 'move back to In Progress before touching code', Blocked tasks with 'resume only if the blocker cleared'; rules footer teaches the four land-the-plane exits up front. Template gains the In-Progress-never-survives-a-stop line plus both parked-state rules (mirrors this repo's CLAUDE.md). Verification, scratch repo E2E: NHA section rendered with task listed and return-path line; same task moved to Blocked rendered under the Blocked section; rules footer line confirmed. Repo gate green. README file-table row updated.
<!-- SECTION:NOTES:END -->
