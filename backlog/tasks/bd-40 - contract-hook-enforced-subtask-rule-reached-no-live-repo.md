---
id: BD-40
title: 'contract: hook-enforced subtask rule reached no live repo'
status: Review
assignee: []
created_date: '2026-08-25 22:11'
updated_date: '2026-08-25 22:36'
labels: []
dependencies: []
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Walter 0.2.0 hook-blocks an action that no live repo's contract mentions.

Measured 2026-08-26 across all three onboarded repos. Grep for "subtask", "commitment" and "parent.sh" in each CLAUDE.md returns 0, 0, 0 in every one:

  Riots-Vasco          subtask:0 commitment:0 parent.sh:0
  ShannonAndTheRiots   subtask:0 commitment:0 parent.sh:0
  automation-pal       subtask:0 commitment:0 parent.sh:0

Their Focus blocks still read "ONE active task at a time" (automation-pal: "ONE task In Progress at a time"), which is the pre-BD-25 wording. BD-25 shipped the commitment model to templates/claude-md-section.md and to guard-transitions.sh, but nothing migrated the live repos.

Two consequences, in order of severity.

First, an enforcement with no contract behind it. guard-transitions.sh denies "task create -p" in every repo. No repo contract says subtasks are human-defined, none names parent.sh, and none says a parent plus its subtasks is one commitment. An agent in Riots-Vasco can be denied for an action its contract never prohibited, and the denial names a script the contract never introduced. This is the failure mode walter exists to prevent, running inside walter.

Second, a live contradiction in a single context window. session-start.sh injects "ONE active commitment at a time ... A commitment is one task, or a parent task with its subtasks", while the same session's CLAUDE.md says "ONE active task at a time". Same shape as BD-34's claim_gate contradiction, different key.

Why the upgrade path did not catch it. commands/onboard.md step 2 refreshes the contract only "if its State honesty block lacks the parked-state rules". All three State honesty blocks are current, so the check passes and the Focus drift survives untouched. The detection condition tests one block; the drift is in another.

What makes a fix hard, and why this is Triage rather than To Do. Widening detection to the whole Board discipline section means distinguishing three things a naive diff cannot tell apart: template boilerplate, the fill-in slots ({{TEST_COMMAND}}, {{DOD_BASELINE_ITEMS}}, {{WORKING_STYLE_NOTES}}), and legitimate per-repo adaptation. All three repos carry real adaptations that must survive any refresh: Riots-Vasco's per-song firewall line and its "human ears are the gate" verification, ShannonAndTheRiots' note that Review means the human took it for a spin in actual music production and that long Review dwell is expected. A refresh that flattens those is worse than the drift.

Note the constraint BD-34 already established: an automatic drift detector was reviewed and rejected on self-authentication grounds (backlog/decisions/2026-08-25-what-the-dogfood-review-refuted.md). A human-run repair, in the shape of the BD-34 repair script, is the only path that decision leaves open. Do not reopen the detector question without a new decision doc.

Smallest honest first cut, if this is promoted: forget generalised drift detection. Add the four missing Focus bullets to each repo by hand, three files, and separately make the upgrade check name what it did NOT examine instead of reporting the repo current. The second half is the durable part; BD-34 recorded that the check's "no-op success" already told two repos they were fine while they carried drift.

Discovered while reloading the plugin after the 0.2.0 release. References BD-34, BD-25.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #2 README updated if behavior changed
- [x] #3 plugin.json and marketplace.json versions bumped if the change is meaningful
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Scope as delivered. automation-pal is archived (human, 2026-08-26), so the by-hand repair covers two live repos, not three. The durable half is done and shipped here.

WHAT WAS BUILT

scripts/contract-drift.sh. Compares a repo's installed "## Board discipline" section against templates/claude-md-section.md block by block and prints a report. Deliberate properties, each one a defence against how the old check failed:
  - It never emits a "current" verdict. Every run ends with a NOT EXAMINED list.
  - It reports, it does not repair. Exit 0 on any readable repo; exit 2 only on unusable input. It is not a gate, so there is nothing to self-grant.
  - Per-repo adaptation is surfaced as REPO-ONLY and pushed into NOT EXAMINED as an open question for the human, never as drift to flatten. This is the constraint BD-40 named: Riots-Vasco's per-song firewall and ShannonAndTheRiots' "took it for a spin in actual music production" must survive any refresh.
  - Blocks carrying fill-in slots are SKIPped and named as permanently uncomparable.
  - It states that verbatim comparison cannot distinguish a reworded bullet from a dropped one, and that it never read .board/config.json or backlog/config.yml.

commands/onboard.md step 2 now runs that script, requires the report be shown in full including its tail, forbids compressing it to a verdict, and forbids bulk-replacing the section with the template.

This does NOT reopen the detector question. BD-34's rejection was of a SessionStart staleness check that granted a "current" verdict with no human in the loop, which an agent could satisfy by rewriting the policy. This is the human-run repair shape that decision leaves open: a human invokes it, a human reads it, and it grants nothing.

EVIDENCE

Run against the two live repos, read-only. Riots-Vasco: all four template Focus bullets MISSING, its two pre-BD-25 lines REPO-ONLY; three State honesty rewordings surfaced as unjudged rather than silently accepted, which the old check would have passed; Board integrity verbatim; its three working-style lines correctly parked as adaptation. ShannonAndTheRiots: same four Focus bullets MISSING, and its Review-means-a-test-spin line preserved as REPO-ONLY. Both reproduce BD-40's measurement exactly.

Run against walter itself: every block verbatim except the deliberate Meatbag-for-Needs-Attention rename, correctly reported as a repo-only line for a human to judge rather than as drift.

tests/bd40-e2e.sh, 30 assertions. Per tests/README.md the suite must be shown to detect the bug it covers, so three mutants were built and each went red:
  - "current" verdict restored, NOT EXAMINED removed -> 2 failures
  - grep option-injection restored (bullets begin "- ", so an unguarded grep ate them as flags; the first cut had this bug and printed every line as both MISSING and REPO-ONLY) -> 3 failures
  - slot detection narrowed back to bullets only, which misses the non-bullet {{WORKING_STYLE_NOTES}} and reports every repo's working-style notes as drift -> 1 failure

Full tree: gate green; tests/*-e2e.sh PASS=242 FAIL=0 (27/29/60/38/12/17/30/29). Was 212 across seven suites; bd40 adds 30.

AC1 met in throwaway repos under mktemp, not in automation-pal, which is archived. See BD-42.
AC2 README updated: the upgrade-check paragraph rewritten to say which half is fixed and which is not, tree entry, test counts, sharp-edges heading to v0.3. tests/README.md gains a row.
AC3 version bumped 0.2.0 -> 0.3.0 in plugin.json and marketplace.json. New script plus changed command behavior is a minor bump.

NOT DONE, AND WHY

The two CLAUDE.md edits are not mine to make. Work belonging to another repo leaves as a prompt, not a patch, and these are human-authored contract files. Exact proposed text is in the handoff below; nothing in Riots-Vasco or ShannonAndTheRiots was written to, only read.

Until those two land, the condition BD-40 describes is still live in both: guard-transitions.sh denies subtask creation there while neither contract mentions subtasks, parent.sh, or the commitment model.

HANDOFF — the two contract edits, for the human to apply in each repo

Riots-Vasco, /Users/vascoorey/Riots-Vasco/CLAUDE.md, the **Focus** block. Replace its two bullets with these four. The claim-gate sentence is this repo's adaptation and is carried into bullet four unchanged in meaning; the template has no such rule and must not overwrite it.

- ONE active commitment at a time, counting `In Progress` and `Pairing` together. A commitment is a single task, or a parent task together with its subtasks. Verification happens once, on the parent, covering the batch.
- Batches are human-defined. You may not create a subtask (hook-enforced). Propose a bundle and hand over the `parent.sh` command for the human to run; the guard denial prints its full path.
- A parent's subtasks are work you have already claimed. Never pull one separately.
- `To Do → In Progress` is human-gated: ask before claiming (contract-level, not hook-enforced). Once claimed, stay on the commitment until it reaches Review. Do not expand its scope.

ShannonAndTheRiots, /Users/vascoorey/ShannonAndTheRiots/CLAUDE.md, the **Focus** block. Same first three bullets, then:

- Pull from To Do, set In Progress via the CLI *before* touching code — and in this repo, ask the human before claiming (To Do → In Progress is human-gated at contract level). Stay on the claimed commitment until it reaches Review. Do not expand its scope.

Leave every other block in both repos alone. The State honesty and Discovered work rewordings the report flags are per-repo voice, not drift: Riots-Vasco says "a flat section, a tempting rework, a missing take" where the template says "a bug, a tempting refactor, a missing dependency", and that is the point of having a per-repo contract.

After applying, re-run `bash /Users/vascoorey/Developer/walter/scripts/contract-drift.sh <repo>` and expect the Focus block to show zero MISSING lines and one REPO-ONLY line, the claim-gate sentence, listed as unjudged.
<!-- SECTION:NOTES:END -->
