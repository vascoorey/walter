---
id: BD-7
title: 'onboard: configurable task prefix (interview + upgrade path)'
status: Done
assignee: []
created_date: '2026-08-20 11:00'
updated_date: '2026-08-20 11:14'
labels:
  - onboard
dependencies: []
ordinal: 15.625
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Requested 2026-08-20. Backlog.md supports task_prefix in backlog/config.yml (default 'task'). Two additions: (1) Step 3 interview explicitly asks what prefix the repo wants (e.g. per-repo codes like 'AP', 'BD'); Step 2 applies it. (2) The Step 1 upgrade check offers changing the prefix on an already-onboarded repo. Open question to investigate: what backlog 1.50.1 actually does with pre-existing task IDs/filenames when task_prefix changes mid-board — whether old tasks keep resolving or need renaming; the upgrade step must handle that honestly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Step 3 interview asks for task prefix; Step 2 applies it
- [x] #2 Upgrade check offers prefix change with existing-task behavior verified and documented
- [x] #3 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #4 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: Step 3 interview gains question 6 (task prefix, default task-N, per-repo codes for unambiguous cross-repo refs); Step 2 applies it BEFORE seeding tasks. Upgrade check gains item 4 with the verified mid-board migration recipe. Investigation findings (backlog 1.50.1, scratch E2E): bare prefix change orphans all existing tasks (files remain, invisible to list/edit) and restarts IDs at 1 -> duplicate-id risk; recovery = rewrite frontmatter id + rename files to LOWERCASE new prefix (scanner only finds lowercase-prefixed filenames; uppercase renames stay invisible); after correct rename everything resolves and next ID continues the sequence (ap-3). Bonus finding: guard-transitions correctly blocks agents from the rename, so the documented flow has the agent write .board/migrate-prefix.sh and the human run it. Fresh path verified separately: prefix set pre-seeding -> bd-1 created and listed cleanly. README updated (interview list + upgrade paragraph). Repo gate green.
<!-- SECTION:NOTES:END -->
