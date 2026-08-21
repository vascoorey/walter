# walter

Kanban-driven agent workflow for Claude Code. The board (Backlog.md) is the invariant — the single source of truth for intent and task state across every repo. *How* work gets done varies per repo and is defined once, at onboarding. Hooks make the state honest; prompts alone don't.

## What it enforces vs. what it asks

| Rule | Mechanism |
|---|---|
| `Done` is human-only; agent tops out at `Review` | **Hook** (PreToolUse denies the CLI transition) |
| `Pairing` is human-only to enter; agent may recommend, never set | **Hook** (PreToolUse denies the CLI transition) |
| Cannot stop with red tests | **Hook** (Stop-gate runs the repo's verification command) |
| Cannot stop with tasks left dangling In Progress | **Hook** (Stop-gate "land the plane" check, first attempt — honest exits: Review, Blocked, Needs Attention, or a follow-up task) |
| No direct edits to task files; CLI only | **Hook** (PreToolUse on Write/Edit + best-effort Bash catch) |
| No rogue TODO.md / PLAN.md / TASKS.md | **Hook** (PreToolUse on Write/Edit + best-effort Bash catch) |
| Real-time status updates, one task In Progress | **Contract** (CLAUDE.md) + SessionStart reinforcement |
| Discovered work → new Triage task, stay focused | **Contract** (CLAUDE.md) + Stop-gate nudge |
| Board + decisions injected at session start | **Hook** (SessionStart, stdout becomes context) |

## Install

```bash
# Prereqs (per machine)
npm i -g backlog.md        # or: brew install backlog-md
brew install jq

# Plugin (local development / testing)
chmod +x walter/hooks/scripts/*.sh
claude --plugin-dir /path/to/walter
```

Verify with `claude --debug` (look for "loading plugin"), and check `/hooks` shows the three events registered.

> `--plugin-dir` loads the plugin for that invocation only (works with headless `claude -p` too). For a permanent install, use a marketplace or the skills directory per current docs: https://code.claude.com/docs/en/plugins-reference.md

## Per-repo onboarding

In any repo:

```
/walter:onboard
```

~10 minutes. It initializes the board, interviews you (verification command, human gates, DoD baseline, current streams, working style, task prefix), writes `.board/config.json`, appends a <40-line contract to `CLAUDE.md`, and seeds initial tasks. All per-repo variation lives in that config + board; the plugin never changes.

Re-running `/onboard` on an already-onboarded repo runs an upgrade check instead: it adds any missing workflow columns (`Pairing`, `Blocked`, `Needs Attention`) to `backlog/config.yml` and refreshes the CLAUDE.md contract section, confirming each change first. On request it also migrates the task prefix — a scripted rename the human runs themselves, since changing `task_prefix` on a non-empty board otherwise orphans every existing task (and the task-file guard rightly blocks agents from doing the rename).

## Board shape

```
Triage → To Do → In Progress → Review → Done
  ↑        ↑          ↕           ↑        ↑
agent    human    Blocked /     agent    HUMAN
writes   promotes  Needs        ceiling  only
                   Attention

                 Pairing    second active column, human-only entry,
                            survives a stop, exits wherever
                            In Progress can
```

- **Triage** is the scope-containment valve: agents write discovered work there, never pull from it.
- **In Progress** strictly means an agent is actively executing. Two parked states branch off it: **Blocked** (external impediment) and **Needs Attention** (ball in the human's court — the agent's honest exit at a stop, instead of fake-promoting to Review). Resuming a parked task means moving it back to In Progress first.
- **Pairing** is the other active column, for work that is a genuine back-and-forth with you. It deliberately survives a stop and the agent keeps working it, code included, without the park-and-resume round-trip. Only *you* can put a task there; the agent can recommend it and cannot set it, which is what keeps a relaxed gate from becoming the cheapest exit. The agent moves it out on its own once the thread concludes.
- **Review → Done** is your gate. Review evidence lives on the task (checked acceptance criteria + verification notes). Web board: `backlog browser`.

## Files

```
.claude-plugin/plugin.json        manifest
commands/onboard.md               /onboard interview + setup
hooks/hooks.json                  event wiring
hooks/scripts/lib/board.sh        every board-tool touchpoint (queries, id pattern, guard patterns)
hooks/scripts/session-start.sh    context injection (board, claimed task, parked tasks, decisions)
hooks/scripts/guard-transitions.sh  denies human-gated transitions + bash writes to task/plan files
hooks/scripts/guard-task-files.sh   CLI-only mutations; blocks rogue plan files (Write/Edit)
hooks/scripts/stop-gate.sh        red tests / dangling tasks block completion
templates/claude-md-section.md    per-repo contract template
```

## Known sharp edges (v0.1)

- **Green runs are cached by content.** The verification command is skipped when repo content (HEAD, tracked diff, untracked file hashes, the command itself) is unchanged since the last green run — chat-only turns don't pay test latency. Stale-green window: failures caused by non-file state (env, services, flakes) won't retrigger until content changes. Outside a git repo, tests run every stop.
- **Stop-gate timeout = 600s.** A verification suite slower than that gets canceled — and a canceled hook renders *no decision*, so the gate silently passes. Keep the gate command fast (unit tier), or raise the timeout.
- **Loop cap = 3 blocks/session.** If the agent can't get tests green in 3 stop attempts, the gate yields with a warning rather than looping forever. Once the cap is hit, the gate stays disarmed for the rest of that session (deliberate — prevents re-looping). A resume or compaction that changes the session id re-arms it. Tune in `stop-gate.sh`. Plugin state in `/tmp` (counters, green stamps) self-prunes after 7 days.
- **Guards are string-matching**, not a shell parser. Bash-side writes to task/plan files (`sed -i`, redirects, `tee`, `mv`/`cp`/`rm`) are caught best-effort; a determined bypass is still possible. Good enough for honest-but-forgetful; not adversarial-proof. Side effect: a gated status name inside quoted prose (e.g. `--notes "human set -s Done"`) also blocks — fails safe, rephrase the note.
- **Backlog.md CLI flags drift between versions.** Verified against 1.50.1: `backlog board --plain` doesn't exist (the script falls back to `backlog task list --plain`), and task IDs print uppercase (`TASK-1` — greps are case-insensitive for this). Smoke-test against your installed version.
- **Worktrees:** the board lives in-repo, so each worktree sees the branch's board state; merges of `backlog/tasks/*.md` are plain-markdown merges. Keep tasks small to avoid conflicts.
- **Gating `To Do → In Progress`** is contract-only in v0.1. Hook-enforcing it needs claim-tracking state; add later if agents start grabbing unreadied work.
