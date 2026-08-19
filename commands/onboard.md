---
description: Onboard this repo onto the board-discipline workflow — initialize Backlog.md, define per-repo ways of working, write config and CLAUDE.md contract.
---

You are onboarding this repository onto a kanban-driven agentic workflow. The board (Backlog.md) is the single source of truth for intent and state; how work gets done varies per repo and is defined right now, with the user.

## Step 1 — Check prerequisites

- Run `backlog --version`. If missing, tell the user to install it (`npm i -g backlog.md` or `brew install backlog-md`) and stop.
- Run `jq --version`. If missing, tell the user (`brew install jq`) and stop.
- Check whether `backlog/` and `.board/config.json` already exist. If both exist, say the repo is already onboarded, show the current config, and ask if they want to revise it instead.

## Step 2 — Initialize the board

- Run `backlog init "<repo name>" --agent-instructions none --check-branches false --include-remote false` (bare `backlog init` opens an interactive wizard that hangs in a tool call — always pass these flags; verified against backlog 1.50.1).
- Configure statuses to include the workflow columns. Target status set (confirm with user in Step 3 before applying): `Triage`, `To Do`, `In Progress`, `Review`, `Done`. Edit `backlog/config.yml` statuses accordingly.
- Create `backlog/decisions/` if it doesn't exist.

## Step 3 — Interview: ways of working for THIS repo

Ask the user these questions (concisely, one message, numbered). Do not skip any; do not assume answers from other repos:

1. **Verification command** — what single command proves the code works here? (e.g. `swift test`, `cargo test`, `npm test`, a script). This becomes the Stop-gate; the agent cannot finish while it's red.
2. **Human gates** — which transitions do you personally approve? Default: only `Review → Done`. Do you also want to gate `To Do → In Progress` (i.e. agents only work tasks you've explicitly readied)?
3. **Definition of Done baseline** — beyond tests passing, what must always be true? (e.g. no new warnings, docs updated, changelog entry). These become default acceptance criteria seeded onto every task.
4. **Streams of work** — what are the current parallel streams in this repo? (Used to create initial parent tasks/labels so the board reflects reality from day one.)
5. **Working style** — anything about how work should be done here (spec-first, TDD, walking skeleton, commit conventions)? This goes in the CLAUDE.md contract as guidance, not enforcement.

## Step 4 — Write the config

Create `.board/config.json`:

```json
{
  "test_command": "<answer 1>",
  "review_status": "Review",
  "human_gated_statuses": ["Done"],
  "triage_status": "Triage",
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
