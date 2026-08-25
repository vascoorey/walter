# The unit of focus is a commitment, not a ticket

Date: 2026-08-25
Status: accepted
Extends: 2026-08-21-pairing-column.md

## Context

The focus rule read "ONE active task at a time", which an agent reads as one *ticket*.
That is stricter than the thing being protected. The stop-gate only ever counted
`In Progress` lines, so the rule's real content was always "one commitment you are
accountable for at a stop".

The cost is correctness, not convenience. BD-20, BD-21, BD-22 and BD-24 are one
deliverable and three of them edit `session-start.sh`. Worked sequentially, the first
ticket's verification evidence is stale by the time the third lands, and the contract
still calls that a legitimate Review.

## Decision

A commitment is a single task, **or** a parent task together with its subtasks. Claim
the parent; the subtasks come with it; verification happens once, on the parent.

The batch is defined by the human. The agent is hook-blocked from creating subtasks at
all and instead proposes a batch and hands over a command. Same shape as the Pairing
decision: a relaxation the agent can reach for eventually becomes the cheapest legal
exit, and a batch the agent could extend is a batch it could grow indefinitely without
ever breaking the focus rule, which is exactly what the triage protocol exists to stop.

No stop-gate change was needed. Verified, not assumed: with a parent active and its
subtasks parked, the gate's id-matching count returns 1.

## Measurement trail: do not re-derive this

Verified against backlog 1.50.1 on 2026-08-25, in a throwaway board.

**The dotted subtask id (`BD-31.1`) is not load-bearing.** Setting only the frontmatter
field `parent_task_id` on an ordinary task makes backlog treat it as a subtask in full:
it appears under the parent's `Subtasks` section, `task list -p` returns it, and
`doctor` stays clean. The task keeps its own id and its own filename.

**That field survives CLI edits.** A subsequent `task edit` rewrites the frontmatter and
adds `updated_date` while preserving `parent_task_id`. The whole design rests on this,
so it was tested rather than assumed.

**`task list --plain` renders subtasks flat**, indistinguishable from top-level tasks.
This is why `session-start.sh` has to say explicitly that a parent's subtasks are
already-claimed work. Without that line the injection invites the agent to pull work it
is already committed to.

**`task edit` has no `--parent` flag**, which is the entire reason a script exists.

## Rejected

**Copy, rewrite the id, archive the original.** This was the planned design and the
probe above killed it. It would have changed `BD-21` into `BD-31.2`, which is why the
ticket originally carried acceptance criteria about rewriting inbound references and
printing an old-to-new id map. None of that is needed. Those two criteria were left
unchecked on the ticket rather than quietly reinterpreted, because checking them as
written would have been a false claim.

**Milestone-based bundling.** Milestones are the retrofittable grouping and `task edit`
does accept `-m`, so this was the fallback if re-parenting proved impossible. It did
not. Milestones remain the right mechanism for BD-17's grouping and are not needed here.

**Targeted denial** (block a subtask create only when the named parent is active). It
needs a board query on a hot path that currently does zero I/O, and it leaves a
relaxation the agent can reason its way into. Rejected in favour of blanket denial.

## What the blanket denial actually cost

Blanket denial was chosen partly because a pure string match has no hot-path cost. The
hidden cost showed up immediately: breadth in the *matcher*, not in the policy.

The first implementation checked two conditions independently across the whole command,
a `create` subcommand anywhere and the parent flag anywhere. Any unrelated short flag of
that letter therefore triggered it, and `mkdir -p` beside a plain task creation was
enough. It was found when the guard blocked the writing of its own test file. The fix is
one regex requiring both in the same command segment.

The policy was right. The matcher was wrong. Worth separating those two when reviewing
any future guard here.

## The finding that generalises

`parent.sh` shipped with a 60-assertion scratch suite proving the mechanism. Dogfooding
it on this repo's own board found three bugs on the first two real invocations:

1. It required the board directory in the working directory, while the `backlog` CLI
   walks up to find it. It refused on the first real use.
2. The subtask guard matched an unrelated `-p` anywhere in the command (above).
3. A repeated title always created a new parent rather than matching the existing one,
   so a re-run made a duplicate parent and silently moved the whole batch onto it,
   leaving the first empty and orphaned.

**All three sat in the seam between the script and the human**: where it looks for the
board, what an argument means, what a re-run means. The frontmatter write, the part
carrying all the data-loss risk, was correct on the first try and stayed correct through
every subsequent change.

The suite could not have found any of them, and not by oversight. A test always passes
an unambiguous argument, from a known directory, exactly once. Those are precisely the
three assumptions a human breaks immediately. A scratch suite proves a mechanism; it
says nothing about whether a tool is usable, and passing one is not evidence that a
human-run script is ready to hand over.

This is the second instance of the same lesson. BD-24 item 1 records `migrate-prefix.sh`
shipping without an executable bit and the human hitting permission denied three times.
Both scripts were correct and both were unusable on contact.

## Consequences

- `scripts/parent.sh` ships with walter, executable, human-run.
- `guard-transitions.sh` denies any agent-issued subtask creation, naming both the
  Triage route for discovered work and the `parent.sh` route for bundling.
- `session-start.sh` states that a parent's subtasks are already-claimed work.
- The contract template and this repo's `CLAUDE.md` state the commitment rule.
- The verification gate now covers `scripts/` so the shipped script is syntax-checked.
- Guard false positives are now three, all failing safe and all documented in the README
  sharp edges. The quoted-prose one fired three times in this session alone and is the
  highest-frequency papercut on BD-24.
