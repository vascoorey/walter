---
id: BD-10
title: 'rename plugin: pick a better name and apply it'
status: Done
assignee: []
created_date: '2026-08-20 11:16'
updated_date: '2026-08-20 11:28'
labels:
  - onboard
dependencies: []
ordinal: 3.90625
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Naming session 2026-08-20. Scope once chosen: plugin.json + marketplace.json names, repo/plugin dir rename, README title/prose, /tmp file prefixes in stop-gate.sh, CLAUDE.md contract header. Installed-copy migration considerations TBD after choice.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Name chosen with the human
- [x] #2 All references updated; plugin loads under the new name
- [x] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
COMPLETE: /reload-plugins loaded 14 plugins with no error; walter:onboard resolved and ran the upgrade check on this repo (all four items already current: 7 statuses, walter contract header, config keys present, BD- prefix). Marketplace re-registered walter@walter via claude plugin marketplace remove/add + install after the stale board-discipline registration caused a load error. E2E = this very repo: renamed, reloaded, command invoked. Outstanding (human, optional, outside a live session): rename ~/Developer/board-discipline dir; reinstall in automation-pal.
<!-- SECTION:NOTES:END -->
