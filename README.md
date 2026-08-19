# board-discipline

Kanban-driven agent workflow for Claude Code. The board (Backlog.md) is the invariant — the single source of truth for intent and task state across every repo. *How* work gets done varies per repo and is defined once, at onboarding. Hooks make the state honest; prompts alone don't.

## What it enforces vs. what it asks

| Rule | Mechanism |
|---|---|
| `Done` is human-only; agent tops out at `Review` | **Hook** (PreToolUse denies the CLI transition) |
| Cannot stop with red tests | **Hook** (Stop-gate runs the repo's verification command) |
| Cannot stop with tasks left dangling In Progress | **Hook** (Stop-gate "land the plane" check, first attempt) |
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
chmod +x board-discipline/hooks/scripts/*.sh
claude --plugin-dir /path/to/board-discipline
```

Verify with `claude --debug` (look for "loading plugin"), and check `/hooks` shows the three events registered.

> `--plugin-dir` loads the plugin for that invocation only (works with headless `claude -p` too). For a permanent install, use a marketplace or the skills directory per current docs: https://code.claude.com/docs/en/plugins-reference.md

## Per-repo onboarding

In any repo:

```
/board-discipline:onboard
```

~10 minutes. It initializes the board, interviews you (verification command, human gates, DoD baseline, current streams, working style), writes `.board/config.json`, appends a <40-line contract to `CLAUDE.md`, and seeds initial tasks. All per-repo variation lives in that config + board; the plugin never changes.

## Board shape

```
Triage → To Do → In Progress → Review → Done
  ↑        ↑                      ↑        ↑
agent    human                  agent    HUMAN
writes   promotes               ceiling  only
```

- **Triage** is the scope-containment valve: agents write discovered work there, never pull from it.
- **Review → Done** is your gate. Review evidence lives on the task (checked acceptance criteria + verification notes). Web board: `backlog browser`.

## Files

```
.claude-plugin/plugin.json        manifest
commands/onboard.md               /onboard interview + setup
hooks/hooks.json                  event wiring
hooks/scripts/session-start.sh    context injection (board, claimed task, decisions)
hooks/scripts/guard-transitions.sh  denies human-gated transitions + bash writes to task/plan files
hooks/scripts/guard-task-files.sh   CLI-only mutations; blocks rogue plan files (Write/Edit)
hooks/scripts/stop-gate.sh        red tests / dangling tasks block completion
templates/claude-md-section.md    per-repo contract template
```

## Known sharp edges (v0.1)

- **Stop-gate timeout = 600s.** A verification suite slower than that gets canceled — and a canceled hook renders *no decision*, so the gate silently passes. Keep the gate command fast (unit tier), or raise the timeout.
- **Loop cap = 3 blocks/session.** If the agent can't get tests green in 3 stop attempts, the gate yields with a warning rather than looping forever. Once the cap is hit, the gate stays disarmed for the rest of that session (deliberate — prevents re-looping). Tune in `stop-gate.sh`.
- **Guards are string-matching**, not a shell parser. Bash-side writes to task/plan files (`sed -i`, redirects, `tee`, `mv`/`cp`/`rm`) are caught best-effort; a determined bypass is still possible. Good enough for honest-but-forgetful; not adversarial-proof. Side effect: a gated status name inside quoted prose (e.g. `--notes "human set -s Done"`) also blocks — fails safe, rephrase the note.
- **Backlog.md CLI flags drift between versions.** Verified against 1.50.1: `backlog board --plain` doesn't exist (the script falls back to `backlog task list --plain`), and task IDs print uppercase (`TASK-1` — greps are case-insensitive for this). Smoke-test against your installed version.
- **Worktrees:** the board lives in-repo, so each worktree sees the branch's board state; merges of `backlog/tasks/*.md` are plain-markdown merges. Keep tasks small to avoid conflicts.
- **Gating `To Do → In Progress`** is contract-only in v0.1. Hook-enforcing it needs claim-tracking state; add later if agents start grabbing unreadied work.
