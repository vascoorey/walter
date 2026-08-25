---
id: BD-36
title: record what the review refuted so it is not rebuilt
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
labels: []
dependencies: []
ordinal: 25000
parent_task_id: BD-37
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The 2026-08-25 codex review refuted nine of ten build proposals, several with citations worth keeping. A Review-entry integrity gate is self-grantable because the CLI lets an agent remove or replace the criteria it wrote, and the incident offered as evidence turned out to have every criterion checked. An unconditional Review-consistency gate would have blocked BD-25, which deliberately left two obsolete criteria unchecked rather than claim them falsely. BD-29's premise is falsified: Stop is not a session-end signal, and one Riots-Vasco session received five Stop prompts between 09:49 and 10:16. A runtime enforcement-attestation registry is answered by the observation that eleven agent-issued Done mutations succeeded immediately before a Done probe was denied, so presence of a hook is not the thing that varied. This is a handoff, not a delete: write it into backlog/decisions/ with the citations so none of it gets re-proposed in three weeks.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->
