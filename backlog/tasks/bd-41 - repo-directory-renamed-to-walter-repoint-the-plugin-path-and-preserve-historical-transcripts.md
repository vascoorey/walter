---
id: BD-41
title: >-
  repo directory renamed to walter: repoint the plugin path and preserve
  historical transcripts
status: Review
assignee: []
created_date: '2026-08-25 22:14'
updated_date: '2026-08-25 22:26'
labels: []
dependencies: []
ordinal: 30000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The repo moved from ~/Developer/board-discipline to ~/Developer/walter. Git remote and plugin name were already walter; only the on-disk path changed. Two references break: the settings.json marketplace path (walter is unloaded until fixed) and tools/extract.sh, whose transcript-directory map must gain the new project dir WITHOUT dropping the old one, since every transcript behind the 2026-08-25 dogfood review lives under the old key.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 settings.json marketplace 'walter' source path points at /Users/vascoorey/Developer/walter and the file is still valid JSON
- [x] #2 tools/extract.sh maps BOTH -Users-vascoorey-Developer-board-discipline and -Users-vascoorey-Developer-walter to the label 'walter'
- [x] #3 extract.sh is confirmed by execution to no-op on a missing transcript directory, not merely assumed from the [ -f ] guard
- [x] #4 Repo verification gate green: bash -n over hooks/scripts + scripts, jq -e over the three JSON manifests
- [x] #5 tests/*-e2e.sh run by hand report PASS=212 FAIL=0 total
- [x] #6 After the human reloads plugins, SessionStart is confirmed to actually fire in the renamed directory
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Rename verified as already done: no ~/Developer/board-discipline on disk, remote is git@github.com:vascoorey/walter.git, plugin manifests already walter@0.2.0. Walter was NOT loaded this session (no SessionStart board), consistent with the stale marketplace path.

AC1. ~/.claude/settings.json line 177 changed, one line, extraKnownMarketplaces.walter.source.path -> /Users/vascoorey/Developer/walter. `jq -e .` OK afterwards, zero remaining "board-discipline" hits in that file. Pre-edit copy kept in the session scratchpad.

AC2/AC3. tools/extract.sh keeps the old transcript dir and gains the new one, both labelled walter, with a comment above the array saying renamed repos keep both entries and not to collapse them. Proof by execution, not by reading the guard:
  - Full run, exit 0, empty stderr, 9194 evidence lines: automation-pal 779, riots-vasco 5133, shannon 2200, walter 1082. The walter lines span three distinct sessions: 19935a59 and 4ab03ddf from the OLD dir, 8fd8a1b4 from the NEW one. Nothing the 2026-08-25 review was built on was orphaned.
  - Missing-directory case run for real via a variant pointing at a nonexistent project dir: exit 0, empty stderr, 0 lines for that label, other repos extracted normally. The absent dir is a clean no-op.

AC4. Gate green: bash -n over hooks/scripts/*.sh, hooks/scripts/lib/*.sh, scripts/*.sh, plus jq -e over the three manifests.

AC5. tests/*-e2e.sh run by hand: bd18 27, bd19 29, bd25 60, bd31 38, bd32 12, bd33 17, pairing 29 = PASS=212 FAIL=0.

AC6 open, human-gated. session-start.sh dry-run in the renamed directory prints the full board and exits 0, so the script is not path-broken; anything still silent after /reload-plugins is plugin loading, not this script. The installed copy at ~/.claude/plugins/cache/walter/walter/0.2.0 is byte-identical to the repo on hooks.json, session-start.sh, stop-gate.sh, both guards and lib/board.sh.

Fourth live reference found, NOT touched, reported to the human: ~/.claude/plugins/known_marketplaces.json pins both .walter.source.path and .walter.installLocation to the old directory. That is the CLI's own derived state and BD-10's notes record a stale registration of exactly this kind causing a load error. Remedy is the marketplace remove/add/install cycle from BD-10, in the human's session, not a hand edit.

Green-cache miss on the first Stop after the rename is expected (stamp keyed on pwd | shasum) and was not chased.

HANDOFF: needs the human, twice.
1. Run /reload-plugins. settings.json is already repointed, so this is the load attempt.
2. If walter loads and the next session in ~/Developer/walter opens with a board, AC6 is met and BD-41 can go to Review. If it is silent or errors, the cause is the stale ~/.claude/plugins/known_marketplaces.json entry, and the fix is BD-10's cycle: claude plugin marketplace remove walter, then add /Users/vascoorey/Developer/walter, then install walter@walter.

AC6 MET, human-observed. After the marketplace remove/add/install cycle and /reload-plugins, a fresh session in /Users/vascoorey/Developer/walter opened with the SessionStart briefing: columns, rules, decision docs and the no-active-commitment line. It rendered BD-40 and BD-41 from task files that are still untracked in git, so it is reading the live working directory, not a stale cache.

Registries all clean, zero remaining "Developer/board-discipline" hits: settings.json extraKnownMarketplaces.walter -> new path with walter@walter enabled; known_marketplaces.json source.path AND installLocation both repointed; installed_plugins.json cache reinstalled at 0.2.0, gitCommitSha e8a9381. Reload reported 2 plugins and 4 hooks, matching exactly the 2 enabled plugins and walter's 4 declared hooks (1 SessionStart, 2 PreToolUse, 1 Stop). Reinstalled cache byte-identical to the repo on hooks.json, session-start.sh, stop-gate.sh, both guards, lib/board.sh.

No live probe of the PreToolUse guards was attempted: every command those guards deny is a real board mutation if the guard is absent, so the probe would cause the damage it tests for.

Re-verified against the current tree at handoff, not citing the earlier run: gate green, tests/*-e2e.sh PASS=212 FAIL=0 (27/29/60/38/12/17/29).

Changes are two files: ~/.claude/settings.json (one line, outside the repo) and tools/extract.sh (four lines added, none removed). Uncommitted.
<!-- SECTION:NOTES:END -->
