# Decision: Blocked and Needs Human Attention are distinct columns

Date: 2026-08-20

The stop-gate's per-turn "land the plane" nagging traced to a vocabulary gap: the board could not say "work paused, ball in the human's court", so In Progress covered both "agent executing" and "open mid-conversation", and every stop looked like abandonment.

**Resolution.** In Progress strictly means the agent is actively executing; it should never survive a stop. Two parked states, different semantics:

- **Blocked** — external impediment (dependency, failing upstream, missing access).
- **Needs Human Attention** — ball in the human's court (question, decision, handoff). Resuming one requires moving it back to In Progress before touching code.

The stop-gate logic stays as-is; the columns make its cheapest legal exit the honest one. Known trade-off, accepted: the gate cannot detect true session end, so an agent that forgets the return path leaves tasks rotting in the handoff column — session-start surfacing is the mitigation (task-3).
