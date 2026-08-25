---
id: BD-35
title: 'guards: two of four production firings were false positives'
status: Triage
assignee: []
created_date: '2026-08-25 09:56'
updated_date: '2026-08-25 11:11'
labels: []
dependencies: []
parent_task_id: BD-37
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The codex review's enforcement-reality lens established the real per-hook production firing counts, separating them from walter's own contaminated corpus. Across automation-pal, Riots-Vasco and ShannonAndTheRiots there were four PreToolUse denials in total, and two of them were false positives: a Riots-Vasco denial blocked a read-only 'task list' filtered by Done, and a Shannon task-file denial fired on a command that was not a write. BD-18 was supposed to have closed the read-only query case, so the first job is establishing whether the shipped fix covers the observed command shape or whether the transcript predates it. The wider finding is the ratio: half of what the guards did in production was get in the way, which is the condition the repo's own 'redundant friction blinds' rule is about.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #2 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DEFERRED BY DECISION, with a better fix design recorded for whenever it is picked up.

Not built today. The reasoning is in backlog/decisions/2026-08-25-what-the-dogfood-review-refuted.md: this affects one repo, only when a command touches two or more task files, and the workaround is trivial, while the change itself touches a guard that runs on every Bash call in four repos. That is a poor trade to make on the back of a long session.

The fix that was rejected. Narrowing the delete-verb match to exclude a following hyphen fails in both directions. The character class can consume a segment separator and let the matcher cross into the next command, and dropping the trailing word boundary newly matches any word beginning with those two letters. It is also agent-grantable: a hyphenated wrapper invoked against a task path is caught by the current pattern and would pass under the proposed one.

The fix worth building instead. Do not touch the predicates at all. Add a preprocessing step that neutralises operator-looking basenames inside backlog/tasks/... tokens only, then run the existing redirect/tee/sed/delete/move/copy predicates unchanged against the neutralised string. This is monotonic: it removes the task-prefix collision without weakening any genuine detection, because the wrapper, absolute-path, sudo-prefixed and IFS-separated forms all sit outside a task-path token and are therefore untouched. It also fixes the whole class at once rather than one verb, which matters because the collision was measured across prefixes: RM-, TEE-, MV- and CP- all trip it, SED- escapes only because that branch additionally requires a flag.

Any implementation needs a regression suite covering, at minimum: the exact Shannon two-glob read; single-path reads under each colliding prefix; genuine deletes and redirects into the task directory under a colliding prefix, which must still be blocked; a hyphenated wrapper against a task path, which must still be blocked; and the source-versus-destination cases already covered by the BD-24 probe. Run it under /bin/bash as well as PATH bash, per BD-33.

Scope note from the same analysis, recorded so this is not closed as a duplicate: BD-18 is genuinely complete and covers a different guard. Its scope was read-only status-filter queries reaching the transition matcher, which current source requires an edit or create subcommand to reach. This ticket is about the task-file write matcher, which is a separate predicate. The two production incidents are distinct.
<!-- SECTION:NOTES:END -->
