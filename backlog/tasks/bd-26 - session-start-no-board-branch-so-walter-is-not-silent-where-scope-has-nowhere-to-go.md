---
id: BD-26
title: >-
  session-start: no-board branch so walter is not silent where scope has nowhere
  to go
status: Triage
assignee: []
created_date: '2026-08-25 03:54'
labels: []
dependencies: []
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
All four hooks open with the same two lines: CONFIG=".board/config.json"; [ -f "$CONFIG" ] || exit 0. session-start.sh states the intent outright: "Fail-open: if repo is not onboarded, stay silent."

BD-16 recorded that silence as evidence of health (pre-onboarding sessions exited in 21-52ms and injected nothing) and it is right about the cost side. This ticket argues the opposite side of the same fact: in a repo with no board, walter contributes nothing at all, so discovered scope has no structural destination and lands in the chat or nowhere. That is precisely the condition where routing scope matters most, because there is not even a Triage column to put it in.

Half the rule is mechanically detectable (config absent) and half is not (the agent noticing it has found scope beyond the current task). The second half does not have to be prose: session-start.sh already injects behavioural instruction into context via its Board rules footer. A no-board branch can inject a short halt-and-offer instruction in exactly the repos where it applies, and nowhere else. That beats putting the rule in user-scope CLAUDE.md, which pays the tokens in every session on the machine including directories that will never have a board.

The design problem is the noise floor. Flipping the early exit means walter speaks in every non-onboarded directory the human ever opens. Needs a real guard, candidates: only inside a git repo, only when a package manifest is present, plus a suppression marker for repos deliberately kept boardless. Related: BD-24 item 4 already flags injection size as a growing cost, so whatever this branch emits must be a few lines at most.

Origin: proposed by the human 2026-08-25 as a user-scope CLAUDE.md line, then reclassified here because the trigger is detectable and the instruction has a natural mechanical host.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Guard decided and documented: which directories get the no-board branch and which stay silent
- [ ] #2 Injected text is at most a few lines and names the /walter:onboard route explicitly
- [ ] #3 A deliberately boardless repo has a supported way to suppress it permanently
- [ ] #4 Timing of the no-board path measured and still negligible
<!-- AC:END -->
