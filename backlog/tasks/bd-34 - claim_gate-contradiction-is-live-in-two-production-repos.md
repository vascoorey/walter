---
id: BD-34
title: claim_gate contradiction is live in two production repos
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
labels: []
dependencies: []
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
BD-24 acceptance criterion 3 'Footer and repo claim-gate config no longer contradict' is checked, and the contradiction is still live in the installed instances. BD-24 fixed the plugin by inventing the claim_gate key and wiring session-start.sh to it. It never migrated the repos already onboarded. Riots-Vasco and ShannonAndTheRiots still store the requirement as free-text claim_gate_note / notes that no hook reads, so SessionStart tells the agent 'Pull ONE task from To Do' while the repo's own contract says ask first. Surfaced by the codex review's adoption-seam lens and confirmed against both configs. Two questions to settle: whether the criterion was checked against the wrong scope, and whether onboard.md's upgrade path can detect and repair drift like this at all.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->
