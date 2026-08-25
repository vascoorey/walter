---
id: BD-32
title: parent.sh can truncate a task file and report success
status: Review
assignee: []
created_date: '2026-08-25 09:56'
updated_date: '2026-08-25 11:21'
labels: []
dependencies: []
parent_task_id: BD-37
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found by the 2026-08-25 codex review, then confirmed by direct inspection. scripts/parent.sh:139 does 'cat $TMP > $FILE': the redirect truncates the destination before cat writes, cat's exit status is never checked, and the function's return value comes from the trailing 'rm -f', which is always 0. A partial write therefore leaves a destroyed task file AND reports success, so the caller continues bundling the remaining children. This is the only code in the repo that can destroy user data and it is the one place not using an atomic rename. The review's refuter dismissed this on the grounds that no adopter has hit it and both recorded human runs succeeded; that is the wrong test for a latent corruption path and the finding stands on the source.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #2 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
FIXED. scripts/parent.sh set_parent now stages the rewrite in a temp file created beside the target (so the final mv is a same-filesystem rename, never a copy), seeds it with cp -p to keep the original mode, refuses to rename an empty result over a valid task file, and checks every exit status including mv's.

Evidence. New suite scratchpad/bd32-e2e.sh, 12 assertions, all green: happy path inserts parent_task_id exactly once and every other byte diffs clean against a baseline including a '---' sequence inside the body; re-running replaces rather than appends; a file without frontmatter is refused and left untouched; and the regression case, an unwritable destination, now returns failure with the file byte-identical and no .parent.* temp left behind.

The suite was confirmed to detect the original defect: the pre-fix set_parent, run against an unwritable destination, returned 0 and would have printed 'now a subtask of X' for a child it never modified, then continued to the next one. That false success is the half demonstrated directly. The truncation half is structural rather than reproduced: 'cat > FILE' truncates before writing, so a short or interrupted write leaves a partial file. Both are closed by the same change.

Note on the review that found this: the codex refuter marked it refuted because no adopter had hit it and both recorded human runs succeeded. That is the wrong test for a latent corruption path, and the defect was confirmed by direct inspection of scripts/parent.sh:139 rather than by transcript evidence.
<!-- SECTION:NOTES:END -->
