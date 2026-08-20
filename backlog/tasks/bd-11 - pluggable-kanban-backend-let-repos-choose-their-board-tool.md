---
id: BD-11
title: 'pluggable kanban backend: let repos choose their board tool'
status: Triage
assignee: []
created_date: '2026-08-20 11:24'
labels: []
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Requested 2026-08-20, parked deliberately. Today the plugin is hard-wired to the backlog CLI (hooks grep its --plain output, guards match backlog/tasks/ paths, onboard drives backlog init). Question: abstract the board operations (list by status, edit status, create task, check AC) behind a per-repo adapter chosen at onboarding — .board/config.json names the tool, hooks dispatch through it. Candidates beyond Backlog.md: GitHub Projects/Issues, Linear, Jira, plain-markdown boards. Design constraints to weigh: hooks must stay fail-open and fast (stop-gate runs every turn); guards need path/command patterns per tool; the stop-gate's status-transition vocabulary (Review, Blocked, Needs Human Attention) must map onto each tool's states. Stays backlog-driven by default either way.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Decision doc: adapter interface + which backends are worth supporting, or explicit no-go
- [ ] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #3 README updated if behavior changed
<!-- AC:END -->
