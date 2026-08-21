# Pairing: a second active column, human-only entry

Date: 2026-08-21
Status: accepted
Extends: 2026-08-20-handoff-columns.md

## Context

The handoff columns solved dangling state but produced friction of their own. A task
that is genuinely a back-and-forth with the human, BD-10 ("pick a better name") and
BD-12 ("rename the column") being the worked examples, has no honest home. `In Progress`
never survives a stop, so every turn costs a park into the human-attention column and a
move back on resume. `Needs Attention` is also the wrong word for it: nobody is waiting,
both parties are engaged.

## Decision

Add `Pairing` as a second **active** column, positioned directly after `In Progress`.

1. **A task in `Pairing` survives a stop.** The stop-gate's land-the-plane check counts
   `In Progress` only.
2. **The agent may change code while a task sits there**, without moving it to
   `In Progress` first. Discussion tasks converge into implementation inside the same
   task; a handoff at the moment of convergence would re-add the ceremony this removes.
3. **Entry is human-only, hook-enforced.** `guard-transitions.sh` denies the agent
   setting `pairing_status`, with denial text distinct from the `Done` gate (whose
   "move to Review instead" would be wrong guidance here).
4. **The agent may recommend it**: note on the task that the work has become multi-turn
   collaboration, say so in the reply, then park normally and stop. The human moves it.
5. **Exit is not gated.** The agent moves a task out to `Review`, `Blocked`, or the
   human-attention column once the thread concludes.
6. **Focus rule becomes one active task total**, counting `In Progress` and `Pairing`
   together.

## Why human-only entry is the load-bearing part

Every other property of this column is a relaxation of the stop-gate. On its own that is
a Goodhart hazard: the cheapest legal exit would become "declare it a conversation", and
the gate would stop meaning anything. Human-only entry removes the incentive entirely,
because the relaxation is not something the agent can reach for. The agent can ask; it
cannot decide.

This is why `Pairing` does not simply join `human_gated_statuses`. That list is the
`Review` to `Done` end gate. The two are enforced the same way and mean opposite things:
one is a ceiling the agent may not exceed, the other is a door the agent may not open.

## Consequences

- `In Progress` keeps its strict meaning. The invariant that no work dangles silently at
  a stop is preserved, because a human explicitly sanctioned every task that survives one.
- A `Pairing` task can go stale if the human forgets it. Mitigated by session-start
  rendering these tasks in full detail as active work, not by another gate.
- Repos onboarded before this need the column added to `backlog/config.yml`. No
  `.board/config.json` change: `pairing_status` defaults to `Pairing` via jq.
