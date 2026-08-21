---
description: Onboard this repo onto the walter workflow — initialize Backlog.md, define per-repo ways of working, write config and CLAUDE.md contract.
---

You are onboarding this repository onto a kanban-driven agentic workflow. The board (Backlog.md) is the single source of truth for intent and state; how work gets done varies per repo and is defined right now, with the user.

## Step 1 — Check prerequisites

- Run `backlog --version`. If missing, tell the user to install it (`npm i -g backlog.md` or `brew install backlog-md`) and stop.
- Run `jq --version`. If missing, tell the user (`brew install jq`) and stop.
- Check whether `backlog/` and `.board/config.json` already exist. If both exist, the repo is already onboarded — do NOT re-initialize. Run the upgrade check below, then show the current config and ask if they want to revise anything else. Stop after that; skip Steps 2–7.

### Upgrade check (already-onboarded repos)

Older onboardings predate the parked-state columns. Bring the repo current:

1. **Statuses** — read `backlog/config.yml`. If `Pairing`, `Blocked`, or `Needs Attention` is missing from `statuses`, add them between `In Progress` and `Review` (edit the one line; e.g. target `["Triage", "To Do", "In Progress", "Pairing", "Blocked", "Needs Attention", "Review", "Done"]`, preserving any repo-specific names already there). This is required — hooks tell agents to move tasks into these statuses, and the CLI rejects statuses not in this list. `Pairing` is the exception the agent can only be moved *into* by you; explain that when confirming.
2. **Contract** — read the `## Board discipline` section of the repo's `CLAUDE.md`. If its State honesty block lacks the parked-state rules, update that section to match the current template (`${CLAUDE_PLUGIN_ROOT}/templates/claude-md-section.md`), preserving the repo's filled-in verification command, DoD baseline, and working-style notes.
3. **`.board/config.json`** — hooks default `blocked_status`/`human_attention_status`/`pairing_status` to the standard names (`Blocked`, `Needs Attention`, `Pairing`). Add these keys only if the repo's columns are named differently — including boards onboarded when the default was `Needs Human Attention`: for those, either set `"human_attention_status": "Needs Human Attention"` (one line, keeps everything working) or rename the column (add the new status to `config.yml`, move any parked tasks via the CLI, remove the old status).
4. **Task prefix (optional, on request)** — offer to change `task_prefix`. Verified against backlog 1.50.1: changing the prefix orphans every existing task (invisible to list/edit; files remain) and new IDs restart at 1, so a bare config change on a non-empty board causes duplicate IDs. The full migration, in this exact order, with NO new tasks created in between: (a) set `task_prefix` in `backlog/config.yml`; (b) for every file in `backlog/tasks/` (and `backlog/archive/tasks/`, `backlog/completed/` if present): rewrite frontmatter `id: TASK-N` → `id: <NEWPREFIX>-N` and rename the file to **lowercase** `<newprefix>-N - <title>.md` — the scanner only finds lowercase-prefixed filenames; (c) verify with `backlog task list --plain` (all tasks visible, next created ID continues the sequence). The task-file guard rightly blocks agents from these writes: write the migration as a script OUTSIDE `backlog/` (e.g. `.board/migrate-prefix.sh`), show it, and have the human run it themselves (`! bash .board/migrate-prefix.sh`), then delete it.

Confirm each change with the user before applying, then re-run the repo's verification command to show the gate is still green.

## Step 2 — Initialize the board

- Run `backlog init "<repo name>" --agent-instructions none --check-branches false --include-remote false` (bare `backlog init` opens an interactive wizard that hangs in a tool call — always pass these flags; verified against backlog 1.50.1).
- Configure statuses to include the workflow columns. Target status set (confirm with user in Step 3 before applying): `Triage`, `To Do`, `In Progress`, `Pairing`, `Blocked`, `Needs Attention`, `Review`, `Done`. Edit `backlog/config.yml` statuses accordingly.
- Column semantics (explain when confirming): `In Progress` strictly means an agent is actively executing, and never survives a stop. `Pairing` is the second active column, for work that is a genuine back-and-forth with the human: it deliberately survives a stop, and the agent may keep working it (code included) without moving it to In Progress. Entry is human-only — the agent can recommend it but cannot set it, which is what stops it being used to park work where the stop-gate won't look. `Blocked` = external impediment (dependency, failing upstream, missing access). `Needs Attention` = ball in the human's court (question, decision, handoff), the agent's legal parked state at a stop.
- Set `task_prefix` in `backlog/config.yml` to the user's answer from Step 3 (confirm before applying). Do this BEFORE seeding any tasks — changing the prefix on a board with existing tasks requires the file-rename migration from the upgrade check.
- Create `backlog/decisions/` if it doesn't exist.

## Step 3 — Interview: ways of working for THIS repo

Ask the user these questions (concisely, one message, numbered). Do not skip any; do not assume answers from other repos:

1. **Verification command** — what single command proves the code works here? (e.g. `swift test`, `cargo test`, `npm test`, a script). This becomes the Stop-gate; the agent cannot finish while it's red.
2. **Human gates** — which transitions do you personally approve? Default: only `Review → Done`. Do you also want to gate `To Do → In Progress` (i.e. agents only work tasks you've explicitly readied)?
3. **Definition of Done baseline** — beyond tests passing, what must always be true? (e.g. no new warnings, docs updated, changelog entry). These become default acceptance criteria seeded onto every task.
4. **Streams of work** — what are the current parallel streams in this repo? (Used to create initial parent tasks/labels so the board reflects reality from day one.)
5. **Working style** — anything about how work should be done here (spec-first, TDD, walking skeleton, commit conventions)? This goes in the CLAUDE.md contract as guidance, not enforcement.
6. **Task prefix** — task IDs default to `task-N`. A per-repo code (e.g. `AP-N`, `BD-N`) makes cross-repo references unambiguous. Which prefix?

## Step 4 — Write the config

Create `.board/config.json`:

```json
{
  "test_command": "<answer 1>",
  "review_status": "Review",
  "human_gated_statuses": ["Done"],
  "triage_status": "Triage",
  "blocked_status": "Blocked",
  "human_attention_status": "Needs Attention",
  "pairing_status": "Pairing",
  "decisions_dir": "backlog/decisions",
  "dod_baseline": ["<answer 3 items>"]
}
```

If the user gated `To Do → In Progress` in answer 2, add `"In Progress"` handling note: agents must ask before claiming (this is contract-level, not hook-enforced yet — say so honestly).

## Step 5 — Write the CLAUDE.md contract

Append the contract from `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-section.md` to this repo's `CLAUDE.md` (create the file if absent), filling in:
- the verification command,
- the DoD baseline items,
- any working-style guidance from answer 5.

Keep the appended section under 40 lines. Do not duplicate anything hooks already enforce beyond a one-line mention.

## Step 6 — Seed the board

- For each stream from answer 4, create a parent task or label.
- Ask the user for 1–3 concrete near-term tasks and create them with acceptance criteria (seeded with the DoD baseline).
- Show the board (`backlog board --plain`) and confirm it reflects reality.

## Step 7 — Verify enforcement

- Run the verification command once so the user sees the gate is green (or knows it's red before agents start).
- Confirm to the user: what's hook-enforced (Done is human-only; no direct task-file edits; no TODO.md/PLAN.md; can't stop with red tests or unreconciled board) vs. what's contract-only (real-time status updates, triage protocol for discovered work, one-task focus).

Finish with a one-paragraph summary of this repo's ways of working as configured.
