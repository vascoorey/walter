---
id: BD-11
title: 'pluggable kanban backend: let repos choose their board tool'
status: Triage
assignee: []
created_date: '2026-08-20 11:24'
updated_date: '2026-08-20 12:01'
labels: []
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Requested 2026-08-20, parked deliberately. Stays in Triage.

DESIGN SETTLED 2026-08-20 (see the pluggability discussion). Blocked on BD-14, which extracts every backlog touchpoint into hooks/scripts/lib/board.sh; that lib's function boundary becomes this ticket's verb set, so this becomes a mechanical change rather than a rewrite.

Shape: descriptor-driven, data not code. Ship backends/*.json, each describing one board tool: query templates (board summary, ids by status, show one task), the task-id regex, guard patterns (the command grammar that sets a status, plus any protected local path), and the CLI hints injected into prompt text and guard error messages. Adding a backend is one data file and zero shell changes; repos can drop their own into .board/backends/. .board/config.json names the backend and defaults to backlog.

HARD CONSTRAINT (decide before writing code): guard-transitions.sh runs on EVERY Bash tool call with a 10s timeout and does zero I/O today. Guards must stay pure string-matching against the command text. Only SessionStart and Stop may query the backend. Any backend design where 'is this status gated?' requires asking a server is out of scope - it would put network latency on every shell command and fail closed when offline.

REJECTED: read-only pluggability (abstract the queries, no-op the guards for non-backlog backends). It trades the enforcement for the flexibility, and the enforcement is the product.

Best candidate for the second backend is probably NOT GitHub Issues. A plain markdown-directory backend with no CLI drops the 'npm i -g backlog.md' prereq, makes walter self-contained, stays local so both guards remain meaningful, and costs nothing at the PreToolUse boundary. Remote backends (GitHub, Linear, Jira) change the latency and offline profile and have no local task file to protect - weigh separately.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Decision doc: adapter interface + which backends are worth supporting, or explicit no-go
- [ ] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #3 README updated if behavior changed
<!-- AC:END -->
