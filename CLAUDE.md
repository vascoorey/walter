<!-- walter contract — appended by /onboard. Keep under 40 lines. -->

## Board discipline (NON-NEGOTIABLE)

The Backlog.md board is the single source of truth for intent and state. Hooks enforce the hard rules; the rest is on you to follow exactly.

**Focus**
- ONE task In Progress at a time. Pull from To Do, set In Progress via the CLI *before* touching code.
- Stay on the claimed task until it reaches Review. Do not expand its scope.

**State honesty**
- Update status in real time — the moment reality changes, not batched at the end.
- Blocked on something external? Set `Blocked` and note the impediment on the task.
- Ball in the human's court (question, decision, handoff)? Set `Meatbag` and note what you need. When resuming one, move it back to In Progress before touching code.
- You may set at most `Review`. `Done` is human-only (hook-enforced).
- Moving to Review requires: acceptance criteria checked off via the CLI + verification evidence in the task notes.

**Discovered work (the triage protocol)**
- Anything new mid-task — a bug, a tempting refactor, a missing dependency, an idea — becomes a NEW task in `Triage`, referencing the current task. Then return to your task.
- Never act on Triage tasks. Never pull from Triage. The human promotes Triage → To Do.
- If a discovery genuinely blocks your task: create the Triage task, set your task `Blocked`, stop and ask.

**Board integrity**
- All board mutations go through the `backlog` CLI (hook blocks direct task-file edits).
- No TODO.md / PLAN.md / TASKS.md (hook-enforced). Plans live on tasks; decisions live in `backlog/decisions/`.
- Shared decisions are binding. Contradicting one requires a new decision doc, agreed with the human.

**Verification** (Stop-gate runs this — you cannot finish while it's red)
- Command: `bash -n hooks/scripts/*.sh hooks/scripts/lib/*.sh && jq -e . hooks/hooks.json .claude-plugin/plugin.json .claude-plugin/marketplace.json >/dev/null`
- Definition of Done baseline (seeded as acceptance criteria on every task):
  - Verified end-to-end in a scratch repo (../automation-pal or throwaway)
  - README updated if behavior changed

**Ways of working for this repo**
- Hooks stay fail-open: missing config, missing jq, missing backlog CLI must never break a session.
- Verify CLI behavior against backlog.md 1.50.1 before shipping changes that touch it.
