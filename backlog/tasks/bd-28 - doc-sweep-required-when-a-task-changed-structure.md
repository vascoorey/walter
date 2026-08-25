---
id: BD-28
title: doc sweep required when a task changed structure
status: Triage
assignee: []
created_date: '2026-08-25 03:54'
labels: []
dependencies: []
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Requested outright by the human, who named its weakness in the same breath: "hard to enforce but better a gate that catches us every once in a while than a wide open door."

The failure: a task changes how something is laid out, and every doc describing the old layout stays live and confidently wrong. Nothing fails, nothing goes red, and the docs quietly become traps. Evidence from the transcript mining is 7 turns across the corpus where a doc contradicted the artifact after a structural change.

Proposal: a task that changed structure cannot reach Review without naming the docs that described that structure, saying which were reconciled and which are now dead.

The hard part is detection, and it should not be faked. Ideas worth weighing, cheapest first: derive it from the modified-file list (a task touching directory layout, config schema, or public interfaces is structural); a label the agent sets when it makes the change; or a plain question in the Review transition that must be answered rather than auto-passed. The last is weakest but is the only one with no false negatives.

Accept up front that this gate will have false positives and will sometimes be answered with "none". That is the human position on record: a gate that catches it occasionally beats an open door. Worth revisiting after a few weeks of real use to confirm the answers are not degenerating into a reflex "none", which would make it a relaxation the agent grants itself and therefore not a gate at all.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Structural change is detected by a stated mechanism, with its false-positive rate acknowledged
- [ ] #2 Review transition is blocked until the doc question is answered, and empty is not an answer
- [ ] #3 Answering none is legal but recorded, so reflex nones are visible later
- [ ] #4 Reviewed after real use to confirm answers are substantive
<!-- AC:END -->
