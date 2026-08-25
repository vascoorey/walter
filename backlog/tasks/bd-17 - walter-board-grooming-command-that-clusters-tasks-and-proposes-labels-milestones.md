---
id: BD-17
title: >-
  walter: board-grooming command that clusters tasks and proposes
  labels/milestones
status: Triage
assignee: []
created_date: '2026-08-23 02:08'
updated_date: '2026-08-23 02:12'
labels: []
dependencies: []
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Agents creating tasks (especially Triage tasks mid-work) have to invent a label/milestone from a sample size of one. A label vocabulary is a property of the whole board, so per-turn classification drifts: near-duplicate labels, inconsistent names, or nothing at all. Move the decision to a batch step that sees every task at once.

New slash command (name TBD: groom/sweep/cluster) reads the whole board, clusters tasks, and proposes labels and milestones for human approval; applies only what the human confirms, via the CLI.

Backlog 1.50.1 already has everything needed: 'backlog milestone add/list/rename/remove/archive', 'task create -m/--milestone' and '-l/--labels', and 'task list -m/-l' filters. Verified 2026-08-23.

SETTLED (human, 2026-08-23):
1. The contract must ALSO stop the agent guessing labels/milestones on create. Otherwise two vocabularies fight: agent-guessed and sweep-proposed. Creating a task means title, description, acceptance criteria - nothing taxonomic.
2. The sweep reads existing milestones and labels FIRST and prefers reuse over inventing. Otherwise it re-taxonomises the board on every run.
3. The sweep does NOT recommend what to pick up next, and does not propose Triage -> To Do promotions. Grouping is descriptive only. Rationale: what to work on next is a judgement call that depends on several things that change - priorities, what just landed, what the human is in the mood to do, external timing. A batch grooming run cannot see any of that, and baking a stale recommendation into the board is worse than no recommendation. It also keeps the agent's own proposal out of the path of its next task.

Labels are cheap and reversible; milestones are a commitment with an end state. Propose labels freely, milestones only for clusters that are a genuine shippable outcome.

Discovered during BD-16 (dogfood review).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Command reads the full board before proposing anything
- [ ] #2 Existing labels and milestones are reused in preference to new ones
- [ ] #3 Nothing is applied without human confirmation, and only via the backlog CLI
- [ ] #4 CLAUDE.md contract and template stop asking the agent to label tasks on create
- [ ] #5 Verified end-to-end in a scratch repo (../automation-pal or throwaway)
- [ ] #6 README updated if behavior changed
- [ ] #7 Sweep proposes grouping only: no pick-up recommendations, no Triage -> To Do promotions
<!-- AC:END -->
