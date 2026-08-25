---
id: BD-35
title: 'guards: two of four production firings were false positives'
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
labels: []
dependencies: []
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The codex review's enforcement-reality lens established the real per-hook production firing counts, separating them from walter's own contaminated corpus. Across automation-pal, Riots-Vasco and ShannonAndTheRiots there were four PreToolUse denials in total, and two of them were false positives: a Riots-Vasco denial blocked a read-only 'task list' filtered by Done, and a Shannon task-file denial fired on a command that was not a write. BD-18 was supposed to have closed the read-only query case, so the first job is establishing whether the shipped fix covers the observed command shape or whether the transcript predates it. The wider finding is the ratio: half of what the guards did in production was get in the way, which is the condition the repo's own 'redundant friction blinds' rule is about.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->
