---
id: BD-4
title: 'stop-gate: skip Gate 1 test run when nothing changed'
status: Done
assignee: []
created_date: '2026-08-20 10:38'
updated_date: '2026-08-20 11:04'
labels:
  - stop-gate
dependencies: []
ordinal: 62.5
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Gate 1 runs the full test command at every stop, so every conversational turn ends with test-suite latency. Skip when a cached green stamp matches current content: git diff HEAD | shasum plus untracked-file list (git status --porcelain alone misses re-edits to already-dirty files). Cached green can be stale for non-file reasons (env, flaky tests) — the cap-3 escape message stays load-bearing. Not yet approved; human decides independently of the column work.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Green stamp keyed on content hash; test command skipped on match
- [x] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #3 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: Gate 1 skips the verification command when a /tmp green stamp (keyed by cwd hash) matches the current content hash = test command + HEAD + git diff HEAD + shasum of each untracked non-ignored file. Stamp written AFTER the green run so test-generated artifacts stabilize; red runs never stamp; outside git repos caching is disabled (tests always run). Verification, scratch repo E2E with a counting test command: unchanged stop skipped (runs 1->1); tracked edit, untracked add, and untracked content edit each retriggered (the porcelain-only miss case covered); red config blocked with RED reason and did not stamp; reverting to a previously-stamped green state legitimately cache-hit. Stale-green window for non-file state documented in README known limitations. Repo gate green.
<!-- SECTION:NOTES:END -->
