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

Re-running `/onboard` on an already-onboarded repo runs an upgrade check instead: it adds any missing workflow columns (`Pairing`, `Blocked`, `Needs Attention`) to `backlog/config.yml` and reconciles the CLAUDE.md contract section, confirming each change first. **The contract half of that check used to report success either way, and no longer does.** It once refreshed the contract only when the State honesty block was missing a parked-state rule, so a repo whose *other* blocks had fallen behind was examined and pronounced current. That is not hypothetical: it happened to all three onboarded repos, every one of which was still carrying pre-commitment-model `Focus` wording while the hooks enforced the new rules, which meant agents were denied for creating subtasks their contract never mentioned. The check now runs `scripts/contract-drift.sh`, which compares every block, prints what is missing beside what is repo-specific, and always ends by naming what it could not judge — reworded-versus-dropped bullets, prose outside the blocks, and the config files it does not read. It never emits a "current" verdict, and it repairs nothing on its own: live repos carry real adaptations, and no diff can tell those from stale wording, so the human decides line by line.

**The config half is still narrow.** Step 3 adds keys only for parked-status names, so a repo lacking a newer key like `claim_gate` is still examined and passed over. There is deliberately no version marker and no staleness warning: an automatic drift detector was designed and rejected, because a check an agent can satisfy by rewriting the policy is not a check (`backlog/decisions/2026-08-25-what-the-dogfood-review-refuted.md`). Treat re-onboarding as a column migration plus a contract review, not as a way to catch up. Until you do, the hooks adapt: they read the board's real status list and only ever name columns it actually has, so a repo still on the v0.1 five-column board gets land-the-plane options it can act on rather than exits the CLI would reject. If that list can't be read, every mention is kept. On request it also migrates the task prefix — a scripted rename the human runs themselves, since changing `task_prefix` on a non-empty board otherwise orphans every existing task (and the task-file guard rightly blocks agents from doing the rename).

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
scripts/contract-drift.sh         report how an installed contract differs from the template
templates/claude-md-section.md    per-repo contract template
tests/                            behavioural suites for the hooks (see tests/README.md)
tools/                            dogfood-review workflows + transcript extraction
```

## Tests

`tests/` holds 242 assertions across eight suites covering the human-only columns, the
land-the-plane exits, column-aware rendering, the green cache, `parent.sh`'s failure
path, contract drift reporting, and bash 3.2 portability. `bash tests/bd33-e2e.sh`, or loop over `tests/*-e2e.sh`.

**They are not wired into the verification gate.** That gate is still a syntax check.
These suites create git repos, write to `/tmp` and shell out to the `backlog` CLI, so a
flaky one would block every stop in this repo rather than just failing a run. Wiring them
in is tracked separately and needs its own judgement about what belongs on the hot path.
Until then, run them by hand after touching a hook — nothing does it for you.

## Known sharp edges (v0.3)

- **macOS ships bash 3.2, and the hooks have to survive it.** `/bin/bash` is 3.2.57, where a bare `"${arr[@]}"` on an empty array under `set -u` aborts the command. Every empty-capable array expansion therefore uses the `${arr[@]+"${arr[@]}"}` form. This bit once already: the green-cache exclusions defeated their own cache on a stock Mac whenever the shared lib was unavailable, and passed every test because the suites all ran under homebrew bash 5. Anything added here should be exercised under `/bin/bash`, not just whichever bash is first on `PATH`.

- **Green runs are cached by content.** The verification command is skipped when repo content (HEAD, tracked diff, untracked file hashes, the command itself) is unchanged since the last green run, so chat-only turns don't pay test latency. `backlog/tasks/` and `backlog/archive/` are excluded: they are tracked, so without that a task note cost a full verification run, measured at ~2.7s against a ~400ms cache hit. `backlog/decisions/` is deliberately still counted, being authored prose rather than board state. Two known stale/spurious windows: failures from non-file state (env, services, flakes) won't retrigger until content changes, and **committing always busts the cache** even when the working tree is byte-identical, because HEAD moves and the diff empties. That costs one extra run per commit turn and is not worth taxing every stop to fix. Outside a git repo, tests run every stop.
- **Stop-gate timeout = 600s.** A verification suite slower than that gets canceled — and a canceled hook renders *no decision*, so the gate silently passes. Keep the gate command fast (unit tier), or raise the timeout.
- **Loop cap = 3 blocks/session.** If the agent can't get tests green in 3 stop attempts, the gate yields with a warning rather than looping forever. Once the cap is hit, the gate stays disarmed for the rest of that session (deliberate — prevents re-looping). A resume or compaction that changes the session id re-arms it. **The counter resets on every clean stop**, so a session can accrue many blocks in total without tripping the cap: five in one observed session. That is intended. The cap breaks a single stuck stop; a session-long counter would disarm the gate for legitimate later work. Tune in `stop-gate.sh`. Plugin state in `/tmp` (counters, green stamps) self-prunes after 7 days, which can also cost one cache miss.
- **Guards are string-matching**, not a shell parser. Bash-side writes to task/plan files (`sed -i`, redirects, `tee`, `mv`/`cp`/`rm`) are caught best-effort; a determined bypass is still possible. Good enough for honest-but-forgetful; not adversarial-proof. For `mv`/`cp` only the destination counts, so reading files *out* of the task directory is allowed. Known false positives, all failing safe: a gated status name inside quoted prose on a `task edit` (e.g. a note quoting the flag and the word Done), a single command line mixing a read-only status filter with an unrelated edit, and one segment carrying both a task creation and an unrelated `-p` belonging to another tool. Known false negative: a `cp` into the task directory with a trailing redirect. Rephrase the note, or split the line. Read-only queries on their own (`task list -s <status>`, `board -s <status>`) are exempt.
- **Bundling is a script, not a CLI call.** backlog 1.50.1 has `task create -p <parent>` but no `--parent` on `task edit`, so existing tasks cannot be re-parented by the CLI. `scripts/parent.sh <parent> <id>...` does it by setting the `parent_task_id` frontmatter field directly. Verified against 1.50.1: that field alone is what backlog reads, so ids, filenames and every other field survive untouched and the script is idempotent. It finds the board by walking up from wherever you run it, the way the `backlog` CLI does. Pass an existing task id to bundle under that task; pass a title and it creates the parent, refusing if a task already has that exact title so a re-run cannot silently make a second parent and move the batch onto it. It is human-run because the task-file guard blocks agents from writing task files, which is the point: a batch the agent could extend is a batch it could grow without ever breaking the one-commitment rule. The rewrite is atomic: the new frontmatter is staged in a temp file beside the target and renamed over it, so a task file is either the old content or the new one. An earlier version truncated the target first and ignored the write's exit status, which meant a failed write destroyed the file and still reported success, and bundling carried on to the next child.
- **Backlog.md CLI flags drift between versions.** Verified against 1.50.1: `backlog board --plain` doesn't exist (the script falls back to `backlog task list --plain`), and task IDs print uppercase (`TASK-1` — greps are case-insensitive for this). Smoke-test against your installed version.
- **The injection caps the terminal column at 10 tasks** and states how many it omitted. Every other column renders in full. Raise `BOARD_TERMINAL_CAP` in `hooks/scripts/lib/board.sh` if you want more.
- **Worktrees:** the board lives in-repo, so each worktree sees the branch's board state; merges of `backlog/tasks/*.md` are plain-markdown merges. Keep tasks small to avoid conflicts.
- **Gating `To Do → In Progress`** is contract-only, deliberately. Set `"claim_gate": true` and SessionStart tells the agent to ask before claiming instead of to pull; nothing enforces it. Hook-enforcing it would need claim-tracking state, and the observed failure it would catch has not appeared. Note that a repo onboarded before this key existed stores the same policy as free text that no hook reads, which is what BD-34 repaired.
