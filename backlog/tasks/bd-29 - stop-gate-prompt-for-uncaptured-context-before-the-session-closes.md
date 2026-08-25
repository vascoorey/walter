---
id: BD-29
title: 'stop-gate: prompt for uncaptured context before the session closes'
status: Triage
assignee: []
created_date: '2026-08-25 03:54'
labels: []
dependencies: []
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Transcript mining found 13 end-of-session context captures across the corpus. The human initiated every single one. Nothing in walter prompts it, and the superpowers plugin that loosely covered this behaviour was disabled 2026-08-25, so the coverage is now zero.

What gets lost is the reasoning, not the code. Git has the diff. What evaporates is why the rejected approach was rejected, the measurement trail behind a calibrated value, and the facts that will otherwise be re-derived from scratch next session.

The stop gate is the natural host: it already runs at the only moment the agent reliably knows a session is ending, and it already knows how to block with a reason string. A prose rule cannot do this job, because a model has no reliable signal that a session is about to end. That is the whole argument for making it a gate.

Design questions, all open.

1. When does it fire? Firing on every stop would be intolerable. Candidates: only when a task moved to Review this session, only after N turns, or only when the session touched files.

2. What satisfies it? Weakest useful version is a single question that must be answered in the stop response. Stronger version requires a Triage task or a decision doc to exist. The stronger version risks manufacturing empty tickets, which is worse than nothing.

3. It must not become the cheapest legal exit. If "nothing uncaptured" is a free keystroke it will be pressed every time, and the gate trains the exact dishonesty it exists to prevent.

Interaction: BD-24 item 5 notes the block counter is deleted on every clean stop, so a session can accrue blocks without ever tripping the cap of 3. Whatever this ticket adds inherits that behaviour and should be decided alongside it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Firing condition is narrow enough that a normal session is not interrupted every stop
- [ ] #2 The satisfying answer cannot be a free keystroke
- [ ] #3 Interaction with the block counter and cap of 3 is decided deliberately, see BD-24 item 5
- [ ] #4 Verified end-to-end in a scratch repo across both a trivial session and a substantive one
<!-- AC:END -->
