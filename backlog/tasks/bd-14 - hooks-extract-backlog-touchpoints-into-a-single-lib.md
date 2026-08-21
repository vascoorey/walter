---
id: BD-14
title: 'hooks: extract backlog touchpoints into a single lib'
status: Done
assignee: []
created_date: '2026-08-20 12:01'
updated_date: '2026-08-20 12:11'
labels: []
dependencies: []
ordinal: 0.9765625
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Option 1 from the 2026-08-20 pluggability discussion. Today backlog CLI knowledge is duplicated across three hook scripts: four read queries (board summary, ids by status, show one task) plus the prefix-agnostic id regex live in session-start.sh and stop-gate.sh, and the backlog/tasks/ path pattern lives in both guards. BD-8 already demonstrated the hazard: one semantic change (prefix-agnostic ids) had to land in two files, and missing one silently disarms Gate 2 with no test to catch it. Consolidate every backlog touchpoint into hooks/scripts/lib/board.sh as named functions, still hard-wired to the backlog CLI. NO config key, NO adapter interface, NO second implementation - that is BD-11. This is a pure move whose function boundary becomes BD-11's verb set later. Hard constraint: the guards run on EVERY Bash tool call with a 10s timeout, so the lib must add no I/O to that path and must stay fail-open when the lib, config, or CLI is missing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Every backlog CLI invocation and the task-id regex live in hooks/scripts/lib/board.sh; no direct backlog call or id regex remains in session-start.sh or stop-gate.sh
- [x] #2 The backlog/tasks/ path pattern is defined once in the lib and consumed by both guard scripts
- [x] #3 Hooks stay fail-open: missing lib, missing config, missing jq, or missing backlog CLI never breaks a session
- [x] #4 Behavior is unchanged - no new config keys, no adapter dispatch, no second backend
- [x] #5 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #6 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added hooks/scripts/lib/board.sh holding all board-tool knowledge: BOARD_TOOL, BOARD_ID_RE, BOARD_TASK_FILE_RE, BOARD_TASK_DIR, and 10 functions (board_available, board_summary, board_lines_in_status, board_ids_in_status, board_show, board_path_is_task_file, board_cmd_writes_task_file, board_cmd_touches_status, board_cmd_sets_status, board_mutate_hint, board_create_hint). All four hook scripts now source it; none contains a CLI invocation or an id/path pattern of its own.

Collapsed a real divergence risk: the id regex previously existed in two spellings (with and without the optional subtask suffix) across session-start.sh and stop-gate.sh. One constant now serves both the match and extract call sites.

Fail-open, two deliberate patterns: session-start and both guards exit 0 if the lib cannot be sourced (a missing lib means a corrupt install, not a user-environment gap). stop-gate sources with || true instead, because Gate 1 (red verification) has no board dependency and is the load-bearing gate; Gate 2 is conditioned on the lib having loaded. Both paths covered by tests.

Config change beyond the plugin: this repo's verification command now also syntax-checks hooks/scripts/lib/*.sh, since 'hooks/scripts/*.sh' does not reach the subdirectory. Updated in .board/config.json and CLAUDE.md. No new plugin config keys were introduced.

VERIFICATION. Gate green: bash -n over all scripts including lib + jq over the three JSON manifests. End-to-end suite at scratchpad/lib-e2e.sh against a throwaway repo (git init + backlog init + 7-column config + 3 tasks across In Progress / Needs Attention / Blocked): 34 assertions, 34 pass, 0 fail. Coverage: session-start sections and hint text; stop-gate Gate 2 block plus correct count; Gate 2 suppressed when stop_hook_active; Gate 1 red block; clean board passing; guard-transitions across gated status via short and long flags, non-gated status, shell write to a task file, rogue TODO.md redirect, benign and read-only commands; guard-task-files across task file, PLAN.md, ordinary source, board config; fail-open with no .board/config.json for all four hooks; fail-open with the lib deleted, confirming Gate 1 still blocks a red run while Gate 2 skips cleanly.

Left for BD-11: the decisions_dir default in session-start.sh is still the literal backlog/decisions. It is a walter-owned directory rather than a CLI call, so it stays a config default for now; fold it into the backend descriptor when that lands.
<!-- SECTION:NOTES:END -->
