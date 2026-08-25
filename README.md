# walter

Kanban-driven agent workflow for Claude Code. The board (Backlog.md) is the invariant — the single source of truth for intent and task state across every repo. *How* work gets done varies per repo and is defined once, at onboarding. Hooks make the state honest; prompts alone don't.

## What it enforces vs. what it asks

| Rule | Mechanism |
|---|---|
| `Done` is human-only; agent tops out at `Review` | **Hook** (PreToolUse denies the CLI transition) |
| `Pairing` is human-only to enter; agent may recommend, never set | **Hook** (PreToolUse denies the CLI transition) |
| Subtasks are human-defined; agent may propose a bundle, never create one | **Hook** (PreToolUse denies `task create -p`) |
| Cannot stop with red tests | **Hook** (Stop-gate runs the repo's verification command) |
| Cannot stop with tasks left dangling In Progress | **Hook** (Stop-gate "land the plane" check, first attempt — honest exits: Review, Blocked, Needs Attention, or a follow-up task) |
| No direct edits to task files; CLI only | **Hook** (PreToolUse on Write/Edit + best-effort Bash catch) |
| No rogue TODO.md / PLAN.md / TASKS.md | **Hook** (PreToolUse on Write/Edit + best-effort Bash catch) |
| Real-time status updates, one active *commitment* (a task, or a parent with its subtasks) | **Contract** (CLAUDE.md) + SessionStart reinforcement |
| Discovered work → new Triage task, stay focused | **Contract** (CLAUDE.md) + Stop-gate nudge |
| Board + decisions injected at session start | **Hook** (SessionStart, stdout becomes context) |
| DoD baseline shown where tasks get created | **Hook** (SessionStart reads `dod_baseline`) |
| To Do tasks with unmet dependencies marked, not offered | **Hook** (SessionStart, via `task list --ready`) |
| Agents ask before claiming, when the repo says so | **Contract** (`claim_gate` in config, surfaced by SessionStart) |

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

Re-running `/onboard` on an already-onboarded repo runs an upgrade check instead: it adds any missing workflow columns (`Pairing`, `Blocked`, `Needs Attention`) to `backlog/config.yml` and refreshes the CLAUDE.md contract section, confirming each change first. **That check is narrower than it looks, and it reports success either way.** It refreshes the contract only when the State honesty block is missing a parked-state rule, and it adds config keys only for parked-status names — so a repo whose contract has merely fallen behind, or whose config lacks a newer key like `claim_gate`, is examined and pronounced current. This is not hypothetical: it happened to two repos, which were told they needed no changes while carrying exactly that drift. There is no version marker and no staleness warning, so nothing tells an onboarded repo it has fallen behind. Treat re-onboarding as a column migration, not as a way to catch up. Until you do, the hooks adapt: they read the board's real status list and only ever name columns it actually has, so a repo still on the v0.1 five-column board gets land-the-plane options it can act on rather than exits the CLI would reject. If that list can't be read, every mention is kept. On request it also migrates the task prefix — a scripted rename the human runs themselves, since changing `task_prefix` on a non-empty board otherwise orphans every existing task (and the task-file guard rightly blocks agents from doing the rename).

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
- **A parent plus its subtasks is ONE commitment**, not N tasks. Claim the parent; the subtasks come with it and verification happens once, on the parent. The stop-gate counts the parent as a single In Progress task, so the focus rule holds unchanged. Only you define a batch: the agent is hook-blocked from creating subtasks, and instead proposes a bundle and hands you the `parent.sh` command.
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
scripts/parent.sh                 human-run: bundle existing tasks under a parent
templates/claude-md-section.md    per-repo contract template
```

## Known sharp edges (v0.1)

- **macOS ships bash 3.2, and the hooks have to survive it.** `/bin/bash` is 3.2.57, where a bare `"${arr[@]}"` on an empty array under `set -u` aborts the command. Every empty-capable array expansion therefore uses the `${arr[@]+"${arr[@]}"}` form. This bit once already: the green-cache exclusions defeated their own cache on a stock Mac whenever the shared lib was unavailable, and passed every test because the suites all ran under homebrew bash 5. Anything added here should be exercised under `/bin/bash`, not just whichever bash is first on `PATH`.

- **Green runs are cached by content.** The verification command is skipped when repo content (HEAD, tracked diff, untracked file hashes, the command itself) is unchanged since the last green run, so chat-only turns don't pay test latency. `backlog/tasks/` and `backlog/archive/` are excluded: they are tracked, so without that a task note cost a full verification run, measured at ~2.7s against a ~400ms cache hit. `backlog/decisions/` is deliberately still counted, being authored prose rather than board state. Two known stale/spurious windows: failures from non-file state (env, services, flakes) won't retrigger until content changes, and **committing always busts the cache** even when the working tree is byte-identical, because HEAD moves and the diff empties. That costs one extra run per commit turn and is not worth taxing every stop to fix. Outside a git repo, tests run every stop.
- **Stop-gate timeout = 600s.** A verification suite slower than that gets canceled — and a canceled hook renders *no decision*, so the gate silently passes. Keep the gate command fast (unit tier), or raise the timeout.
- **Loop cap = 3 blocks/session.** If the agent can't get tests green in 3 stop attempts, the gate yields with a warning rather than looping forever. Once the cap is hit, the gate stays disarmed for the rest of that session (deliberate — prevents re-looping). A resume or compaction that changes the session id re-arms it. **The counter resets on every clean stop**, so a session can accrue many blocks in total without tripping the cap: five in one observed session. That is intended. The cap breaks a single stuck stop; a session-long counter would disarm the gate for legitimate later work. Tune in `stop-gate.sh`. Plugin state in `/tmp` (counters, green stamps) self-prunes after 7 days, which can also cost one cache miss.
- **Guards are string-matching**, not a shell parser. Bash-side writes to task/plan files (`sed -i`, redirects, `tee`, `mv`/`cp`/`rm`) are caught best-effort; a determined bypass is still possible. Good enough for honest-but-forgetful; not adversarial-proof. For `mv`/`cp` only the destination counts, so reading files *out* of the task directory is allowed. Known false positives, all failing safe: a gated status name inside quoted prose on a `task edit` (e.g. a note quoting the flag and the word Done), a single command line mixing a read-only status filter with an unrelated edit, and one segment carrying both a task creation and an unrelated `-p` belonging to another tool. Known false negative: a `cp` into the task directory with a trailing redirect. Rephrase the note, or split the line. Read-only queries on their own (`task list -s <status>`, `board -s <status>`) are exempt.
- **Bundling is a script, not a CLI call.** backlog 1.50.1 has `task create -p <parent>` but no `--parent` on `task edit`, so existing tasks cannot be re-parented by the CLI. `scripts/parent.sh <parent> <id>...` does it by setting the `parent_task_id` frontmatter field directly. Verified against 1.50.1: that field alone is what backlog reads, so ids, filenames and every other field survive untouched and the script is idempotent. It finds the board by walking up from wherever you run it, the way the `backlog` CLI does. Pass an existing task id to bundle under that task; pass a title and it creates the parent, refusing if a task already has that exact title so a re-run cannot silently make a second parent and move the batch onto it. It is human-run because the task-file guard blocks agents from writing task files, which is the point: a batch the agent could extend is a batch it could grow without ever breaking the one-commitment rule. The rewrite is atomic: the new frontmatter is staged in a temp file beside the target and renamed over it, so a task file is either the old content or the new one. An earlier version truncated the target first and ignored the write's exit status, which meant a failed write destroyed the file and still reported success, and bundling carried on to the next child.
- **Backlog.md CLI flags drift between versions.** Verified against 1.50.1: `backlog board --plain` doesn't exist (the script falls back to `backlog task list --plain`), and task IDs print uppercase (`TASK-1` — greps are case-insensitive for this). Smoke-test against your installed version.
- **The injection caps the terminal column at 10 tasks** and states how many it omitted. Every other column renders in full. Raise `BOARD_TERMINAL_CAP` in `hooks/scripts/lib/board.sh` if you want more.
- **Worktrees:** the board lives in-repo, so each worktree sees the branch's board state; merges of `backlog/tasks/*.md` are plain-markdown merges. Keep tasks small to avoid conflicts.
- **Gating `To Do → In Progress`** is contract-only in v0.1. Hook-enforcing it needs claim-tracking state; add later if agents start grabbing unreadied work.
