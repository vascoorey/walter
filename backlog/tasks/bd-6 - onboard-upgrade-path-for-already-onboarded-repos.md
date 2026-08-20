---
id: BD-6
title: 'onboard: upgrade path for already-onboarded repos'
status: Done
assignee: []
created_date: '2026-08-20 10:48'
updated_date: '2026-08-20 11:00'
labels:
  - onboard
dependencies: []
ordinal: 125
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered during task-1 review discussion (2026-08-20). Migration needs per repo: (1) add Blocked + Needs Human Attention to backlog/config.yml statuses — hard requirement, CLI validates against it; (2) .board/config.json keys — unnecessary if stop-gate/session-start read them with jq // defaults (make that an AC on task-2/task-3); (3) refresh the appended CLAUDE.md contract section with the parked-state semantics. Natural home: /onboard Step 1 already-onboarded branch becomes a diff-and-patch upgrade instead of just 'ask to revise'.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Re-running /onboard on an onboarded repo offers and applies the column + contract upgrade
- [x] #2 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #3 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Done: onboard.md Step 1 already-onboarded branch is now an explicit upgrade check — (1) add missing Blocked/NHA columns to backlog/config.yml statuses (required, CLI validates), (2) refresh CLAUDE.md contract State-honesty block from the current template preserving repo-specific fills, (3) config.json untouched (hook defaults cover standard names). Verification, scratch repo E2E: built an old-style 5-column onboarded repo; pre-upgrade the CLI rejected -s 'Needs Human Attention' (proving step 1 required); applied the checklist exactly as written; post-upgrade the stop-gate blocked with the 4-exit message, the NHA move was accepted, and the gate passed exit 0 with the ORIGINAL config.json unchanged. Repo gate green. README notes the re-run-to-upgrade behavior.
<!-- SECTION:NOTES:END -->
