---
id: BD-12
title: rename 'Needs Human Attention' to 'Waiting'?
status: Done
assignee: []
created_date: '2026-08-20 11:25'
updated_date: '2026-08-20 11:42'
labels: []
dependencies: []
ordinal: 1.953125
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Raised 2026-08-20. 'Waiting' is shorter and reads cleaner on a board, but loses the two properties the long name carries: WHO must act (the human — 'Waiting' could equally read as waiting on CI or a dependency, which is what Blocked already covers) and the imperative nudge (a column literally named 'needs your attention' is a to-do signal for the human scanning the board; 'Waiting' is passive). Alternatives worth weighing if renaming: 'Waiting on Human', 'Your Court', 'Handoff'. Mechanics are cheap either way: statuses line in config.yml, human_attention_status in .board/config.json (hooks read it via config already — defaults would need updating if the standard name changes), template + README wording, and the migration note for onboarded repos. Decide semantics first; the rename itself is minutes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Decision: keep 'Needs Human Attention' or rename (with chosen name); rationale noted
- [x] #2 If renamed: defaults, template, README, upgrade check all updated
- [x] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision: shipped default renamed 'Needs Attention' (15 chars, fits max_column_width 20; the old 21-char name truncated in the TUI); this repo overrides to 'Meatbag' via human_attention_status — deliberately NOT the shipped default. Applied: both script defaults, template, README (table, prose, diagram), onboard.md (status set, semantics, config template), and upgrade check item 3 now covers boards onboarded under the old default (set the config key, or rename the column with CLI moves). This repo: config.yml column renamed with the old column empty, config.json + CLAUDE.md updated. E2E: empty-config gate message says 'Needs Attention'; this repo's gate message says 'Meatbag' (live, BD-12 In Progress triggered it); scratch board renamed to new default accepts the move and the gate passes exit 0. Repo gate green.
<!-- SECTION:NOTES:END -->
