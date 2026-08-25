---
id: BD-34
title: claim_gate contradiction is live in two production repos
status: Review
assignee: []
created_date: '2026-08-25 09:56'
updated_date: '2026-08-25 11:21'
labels: []
dependencies: []
parent_task_id: BD-37
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
BD-24 acceptance criterion 3 'Footer and repo claim-gate config no longer contradict' is checked, and the contradiction is still live in the installed instances. BD-24 fixed the plugin by inventing the claim_gate key and wiring session-start.sh to it. It never migrated the repos already onboarded. Riots-Vasco and ShannonAndTheRiots still store the requirement as free-text claim_gate_note / notes that no hook reads, so SessionStart tells the agent 'Pull ONE task from To Do' while the repo's own contract says ask first. Surfaced by the codex review's adoption-seam lens and confirmed against both configs. Two questions to settle: whether the criterion was checked against the wrong scope, and whether onboard.md's upgrade path can detect and repair drift like this at all.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [x] #2 README updated if behavior changed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
CLOSED. The live contradiction is repaired in all three production repos, and the durable mechanism was deliberately not built.

What was done. A one-off human-run repair (scratchpad/bd34-repair.sh) added the claim_gate boolean, the only key session-start.sh actually reads, to each repo's .board/config.json. It refuses to infer the value from the legacy prose, because the same policy was stored under two differently-named free-text fields and guessing intent from prose is how a migration silently changes policy; it prints the prose beside the proposed value instead. Writes are atomic with a backup and a JSON-validity check before the rename, applying the BD-32 lesson rather than just recording it. It deliberately does not touch CLAUDE.md or backlog/config.yml.

Verified end-to-end by running session-start.sh in each repo after the change, which is stronger than the scratch-repo baseline:
  Riots-Vasco        claim_gate=true   -> "Claiming is gated in this repo: ASK before moving anything to In Progress"
  ShannonAndTheRiots claim_gate=true   -> the ASK line plus the footer gate note
  automation-pal     claim_gate=false  -> "Pull ONE task from To Do", unchanged
Riots-Vasco and Shannon had contracts requiring ask-before-claiming that their hooks had been ignoring since onboarding. automation-pal has no such rule in its contract, so false preserves existing behaviour rather than imposing a new gate.

What was NOT built, and why. The proposed durable freshness mechanism (config schema version plus a SessionStart staleness check) was killed by both review lenses. The blocking defect: it would have been self-authenticating, since an agent could set claim_gate to false, render a matching contract block and obtain a "current" verdict with no human involvement. A drift detector an agent satisfies by changing the policy is the failure the Pairing and subtask denials exist to prevent. Full reasoning in backlog/decisions/2026-08-25-what-the-dogfood-review-refuted.md.

Left open deliberately, all recorded rather than fixed:
- The three CLAUDE.md Focus blocks still predate the commitment model, and all three still say "board-discipline contract" rather than "walter contract". Contract prose is the human's; a scripted merge is a risk not worth taking for stale wording that misleads nobody today.
- automation-pal's status list has no Pairing column. Re-onboarding adds it, and that path genuinely works.
- The legacy claim_gate_note / notes fields remain in place and are now redundant.
- README now states plainly that the upgrade check is narrower than it looks and reports success either way, since two repos were told they were current while carrying this exact drift.
<!-- SECTION:NOTES:END -->
