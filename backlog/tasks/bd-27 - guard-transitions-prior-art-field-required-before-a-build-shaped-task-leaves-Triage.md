---
id: BD-27
title: >-
  guard-transitions: prior-art field required before a build-shaped task leaves
  Triage
status: Triage
assignee: []
created_date: '2026-08-25 03:54'
updated_date: '2026-08-25 03:58'
labels: []
dependencies: []
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The human named this as their own biggest gap, verbatim: "before deciding to build tooling we need an honest and deep survey of the landscape. surely someone has done it and better that we can."

A gate is the right shape for it because the failure is silent. Nobody notices the survey that never happened; they notice it two weeks into a rebuild of something that already exists. The check belongs at the Triage exit because that is the last moment where abandoning the task is still free.

Proposal: a build-shaped task cannot leave Triage without a field naming what already exists and why it does not fit. Empty is not an answer; "nothing comparable found, searched X and Y" is, because it records that the search happened.

Two open design problems, both real.

1. Detecting build-shaped. Gating every bug fix on prior art would be pure friction and would train the cheapest legal exit, which is a one-word field nobody reads. Candidates: a task type, a label, or a size threshold. Prefer an explicit signal over inference.

2. The gate can only check that the field is non-empty. It cannot check that the survey was honest. That is a known ceiling and it should be written down rather than pretended away. The gate buys the pause, not the rigour.

Live evidence that the pause is worth buying, from 2026-08-25: an agent proposed rebuilding a skill packaging step (mkdir, move file, edit plugin.json, reinstall) that the source repo already implemented correctly as scripts/sync-skill.js and documented as npm run sync-skill. It had read the plugin cache and never the repo. Cost of the missing survey was the whole proposed plan, caught only because someone read the source repo by chance.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Build-shaped is detected by an explicit signal, not inferred from the title
- [ ] #2 A task carrying the signal cannot leave Triage with the prior-art field empty
- [ ] #3 Non-build tasks are unaffected, verified with a bug-fix task in a scratch repo
- [ ] #4 The gate documents its own ceiling: it checks presence, never honesty
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
FIELD FORMAT IS THIS TICKET.S JOB, 2026-08-25. The plan originally paired this gate with a user-level research skill that would produce the prior-art write-up in a shape that dropped straight into the field. That skill was reviewed and deleted the same day: 799 bytes, one use in six weeks, and it said nothing the CLAUDE.md Research and Agents section already said. So there is no companion tool. This ticket must define what a credible answer looks like on its own, or the field will fill up with one-word entries and become the relaxation the agent grants itself.
<!-- SECTION:NOTES:END -->
