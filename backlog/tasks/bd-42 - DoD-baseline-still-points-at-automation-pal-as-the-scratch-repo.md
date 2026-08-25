---
id: BD-42
title: DoD baseline still points at automation-pal as the scratch repo
status: Triage
assignee: []
created_date: '2026-08-25 22:35'
labels: []
dependencies: []
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered during BD-40. .board/config.json dod_baseline seeds 'Verified end-to-end in a scratch repo (../automation-pal or throwaway)' as an acceptance criterion on every task, and automation-pal is archived as of 2026-08-26. The path is also wrong from this repo: automation-pal is at ~/Developer/automation-pal, so '../automation-pal' resolved from ~/Developer/walter only ever worked by accident of both living under Developer/.

Two things to decide, not one. First, whether the criterion should name any specific repo at all now that the only named one is archived, or just say 'a throwaway'. Second, whether the archived repo's transcripts should stay in tools/extract.sh: they are 779 lines of the evidence behind the 2026-08-25 dogfood review, so the answer is probably yes and the entry wants a comment saying the repo is archived, the same way the renamed walter dirs got one.

Not urgent and not blocking: the criterion is prose seeded onto tasks, nothing reads the path. References BD-40.
<!-- SECTION:DESCRIPTION:END -->
