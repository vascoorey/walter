---
id: BD-32
title: parent.sh can truncate a task file and report success
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
labels: []
dependencies: []
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found by the 2026-08-25 codex review, then confirmed by direct inspection. scripts/parent.sh:139 does 'cat $TMP > $FILE': the redirect truncates the destination before cat writes, cat's exit status is never checked, and the function's return value comes from the trailing 'rm -f', which is always 0. A partial write therefore leaves a destroyed task file AND reports success, so the caller continues bundling the remaining children. This is the only code in the repo that can destroy user data and it is the one place not using an atomic rename. The review's refuter dismissed this on the grounds that no adopter has hit it and both recorded human runs succeeded; that is the wrong test for a latent corruption path and the finding stands on the source.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->
