# Acceptance criteria: surface the baseline, do not gate the timing

Date: 2026-08-25
Status: accepted
Context: BD-21, discovered by the BD-16 dogfood review

## Context

Two related decays, both measured in Riots-Vasco on 2026-08-23.

**(a) `dod_baseline` was decoration.** The field sat in `.board/config.json`, the
contract told the agent those items were seeded onto every task, and no hook read it.
14 of 38 task files carried the baseline and all 14 were from onboarding day. Every task
created since carried neither.

**(b) Criteria are often written after the work.** RIOTS-25, 20, 35, 36, 37 and 38 all
show criteria authored late and checked off in one blast immediately before the Review
transition. That satisfies the Review gate without the criteria having constrained
anything.

The counter-evidence matters and is why this was a papercut rather than a hole. Tasks
created during deliberate planning carry substantial criteria written before any work,
and RIOTS-36 was honestly reopened from Review with three new criteria when an upstream
skill changed. The rule holds when a task is planned, and decays when a task is minted
reactively mid-work. Review notes carry genuine evidence either way.

## Decision (a): surface the baseline

`session-start.sh` reads `dod_baseline` and emits it in the Board rules footer, next to
the discovered-work rule, where the agent is about to create tasks. An empty array emits
nothing, so repos that declined a baseline see no noise.

The field is now live. It is not enforced.

## Decision (b): no gate on criteria predating `In Progress`

Recorded here because a rejected gate leaves no trace in the code.

A gate can only check that criteria **exist**. It cannot check that they constrained
anything, and that is the entire property worth having. Criteria written to pass a claim
gate are authored in the same breath as the claim, by the same agent, with the work
already decided. They would satisfy the check and change nothing.

Worse, the gate would have a cheapest legal exit: one throwaway criterion per task. Once
that becomes habit, the board looks healthier than it is, which is strictly worse than
the honest decay we can currently see and measure.

The same argument rejected enforcing `dod_baseline` at task creation.

## What this leaves unsolved, deliberately

The late-criteria pattern is real and this decision does not fix it. It relocates it: the
problem is that a task minted reactively mid-work never gets planned, which is a planning
problem, not a gate problem. Triage capture during focused work is supposed to be cheap,
and making it expensive would push discovered work back into the chat where it vanishes.

Worth revisiting if the ratio moves. The measurement that would change this decision is
criteria appearing on *planned* tasks after the work rather than before, which would mean
the decay had spread past reactive capture.

## Consequences

- `dod_baseline` is read by `session-start.sh` and appears in the footer.
- `commands/onboard.md` still asks for it in the interview; that answer now does something.
- No new gate. `guard-transitions.sh` is unchanged by this decision.
- The contract's existing "seeded as acceptance criteria on every task" wording is now
  true by surfacing rather than false by assertion.
