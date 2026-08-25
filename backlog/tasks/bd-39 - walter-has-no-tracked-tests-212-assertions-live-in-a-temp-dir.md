---
id: BD-39
title: walter has no tracked tests; 212 assertions live in a temp dir
status: Triage
assignee: []
created_date: '2026-08-25 11:25'
updated_date: '2026-08-25 11:31'
labels: []
dependencies: []
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Walter has no tracked tests. Its entire verification gate is a syntax check: bash -n over the shell files plus jq validating three JSON manifests. That proves the scripts parse. It proves nothing about what any hook does.

Every behavioural assertion walter has ever had lives in a session-scoped temp directory and will be deleted with it. As of 2026-08-25 that is 212 assertions across seven suites: bd18 (27), bd19 (29), bd25 (60), bd31 (38), bd32 (12), bd33 (17) and pairing (29). They cover the human-gated columns, the Pairing entry restriction, land-the-plane exits, column-aware option rendering, the green cache, dependency marking, the terminal cap, the claim gate, guard source-versus-destination behaviour, parent.sh byte preservation and its failure path, and bash 3.2 portability across every hook entry point.

Consequence: every "verified end-to-end" note on every closed ticket in this repo rests on evidence that is not in the repo and cannot be re-run by anyone else, including a future session. Nothing regression-tests walter. A change that breaks the Done gate, the Pairing restriction or the cache would pass the verification gate and stop cleanly.

The root cause is the Definition of Done baseline itself, which says "Verified end-to-end in a scratch repo (../automation-pal or throwaway)". That phrasing institutionalises untracked verification: it asks for a scratch repo by design, so the suites were always built somewhere disposable and never had a home. Changing the baseline is part of this ticket, not a separate one.

Note the shape of the risk before deciding scope. Copying test files into the repo changes no runtime behaviour and is close to zero risk. Wiring them into the verification gate is the part that needs care, because a flaky or environment-dependent suite in test_command would block every stop in this repo, and several suites create scratch git repos, write to /tmp and depend on the backlog CLI being installed. Those two steps should probably be separate commitments.

Two smaller items from the same session are homeless in the same directory and worth preserving with the suites, though neither is urgent: the two codex review workflow scripts, which encode the lenses-over-clones finding and the latent-defect refuter rule, and the transcript extraction script that produced the evidence pack, which is what makes any future dogfood review reproducible rather than a fresh archaeology exercise.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
PARTLY ADDRESSED. The near-zero-risk half is done: the suites now live in the repo instead of a session temp dir, so they survive this session.

tests/ holds the seven suites plus cpprobe.sh, 212 assertions, all passing from their new location. Every hardcoded path was removed as part of the move: PLUGIN now derives from the script's own location, and the scratch ROOT is a per-run mktemp -d overridable with WALTER_TEST_ROOT, so nothing points at the temp directory any more. tests/README.md documents what each suite covers, the two-interpreter rule from BD-33, and the requirement that a regression suite be shown to detect the bug it covers.

tools/ holds the two dogfood-review workflow scripts and the transcript extraction script, so a future review is reproducible rather than fresh archaeology.

STILL OPEN, and the reason this ticket stays alive: the suites are NOT wired into test_command, which remains a syntax check. Nothing runs them automatically, so a change that breaks the Done gate or the Pairing restriction still passes the verification gate and stops cleanly. That was left deliberately separate because several suites create git repos, write to /tmp and depend on the backlog CLI, and a flaky one on the hot path would block every stop in this repo.

Also still open: the Definition of Done baseline still says 'Verified end-to-end in a scratch repo (throwaway)', which is the phrasing that caused the suites to be homeless in the first place. Changing it belongs with the wiring decision.
<!-- SECTION:NOTES:END -->
