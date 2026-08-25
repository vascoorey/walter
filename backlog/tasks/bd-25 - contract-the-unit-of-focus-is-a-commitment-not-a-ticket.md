---
id: BD-25
title: 'contract: the unit of focus is a commitment, not a ticket'
status: Done
assignee: []
created_date: '2026-08-23 08:00'
updated_date: '2026-08-25 06:30'
labels: []
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The focus rule reads 'ONE active task at a time', which the agent interprets as one ticket. That is stricter than the thing being protected. The stop-gate only ever counted In Progress lines; the rule's real content is 'one commitment you are accountable for at a stop'.

Consequence today: two coupled tickets that should land together must be worked sequentially, each landing in Review with its own verification. When both edit the same file, the first ticket's evidence is stale by the end of the session. That is a correctness problem, not a convenience one.

PROPOSAL: state that the unit of focus is a task OR a parent task together with its subtasks. Claim the parent; subtasks land beneath it; verification happens once, on the parent, covering the batch. No hook change needed - the stop-gate already counts one In Progress.

GUARDRAIL (same shape as the Pairing decision): the batch is defined by the human. The agent may NOT create a subtask under its own active parent, or it can grow its own scope indefinitely without ever breaking the focus rule - exactly what the Triage protocol exists to prevent. Discovered work still goes to Triage; the agent may recommend a subtask, never mint one under itself. Whether that needs a hook or stays contract-level is open; the Pairing precedent says a relaxation the agent can reach for eventually becomes the cheapest exit.

CLI CONSTRAINTS, verified against backlog 1.50.1 on 2026-08-23:
- 'task create -p <parent>' exists; 'task edit' has NO --parent flag, so existing tasks cannot be re-parented. Batches must be planned at creation, or the tasks recreated.
- '-m/--milestone' IS settable on edit, with --clear-milestone. Milestones are the retrofittable grouping - see BD-17.
- 'task list -p <parent>' filters subtasks.

VERIFY BEFORE BUILDING: how the stop-gate and session-start render a parent In Progress with subtasks in To Do, and whether backlog auto-manages parent status.

Do NOT fold in the Triage-promotion friction; that is BD-23. One mechanism for both would serve neither.

Discovered during BD-16 (dogfood review), raised by the human.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Focus rule states the unit is a commitment, covering parent-plus-subtasks
- [x] #2 Agent cannot add subtasks under its own active parent
- [x] #3 Stop-gate and session-start behaviour with a parent In Progress is verified, not assumed
- [x] #4 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #5 README updated if behavior changed
- [x] #6 Bundling is agent-proposed and human-executed, never agent-applied
- [x] #7 Existing task IDs survive bundling; no recreate-and-archive
- [x] #8 parent.sh copies task files rather than round-tripping through the CLI
- [ ] #9 Inbound references to bundled task IDs are rewritten, not orphaned
- [ ] #10 Script ships executable and prints an old-to-new ID map
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
DOGFOOD BUG 3, 2026-08-25, found by the human re-running the same command. A title argument always created a new parent and never matched an existing one, so the second run made a duplicate parent with the identical title and moved all four tasks onto it. The first parent was left empty and orphaned on the board. Per-task the script was idempotent, which is what made this quiet: the re-parenting itself worked perfectly, it just pointed at the wrong parent.

Fixed: a title that exactly matches an existing task's title is refused before anything is touched, listing the ids that already carry it and saying to pass one of them instead. Exact title match, so a title that merely contains an existing one still creates. Nine assertions, including a replay proving the original command is now refused, that no duplicate parent appears, that the first parent keeps its batch, and that bundling by id still works.

Pattern worth naming across all three dogfood bugs. Every one was in the seam between the script and the human, not in the mechanism: where it looks for the board, what an argument means, what a re-run means. The frontmatter write, the part that carries all the risk of losing data, was correct on the first try and has stayed correct through every change. The scratch suite proved the mechanism and could not have found any of these, because a test always passes an unambiguous argument from a known directory exactly once.

VERIFICATION against the current tree, all re-run after the last edit: bd25 60, pairing 29, bd18 27, bd19 29. 145 assertions green across four suites. Repo gate GREEN. README updated with the title-versus-id behaviour.

BOARD STATE LEFT BEHIND: BD-30 is an empty duplicate parent from the first run and BD-31 holds the batch. Cleaning that up is the human's call, not mine.
<!-- SECTION:NOTES:END -->
