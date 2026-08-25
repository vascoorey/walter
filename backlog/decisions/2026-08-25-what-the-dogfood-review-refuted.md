# What the dogfood review refuted, and why we stopped building

Date: 2026-08-25
Status: accepted
Context: BD-36, from the BD-37 batch. Records the output of two adversarial reviews
of the whole plugin, run against 33 real sessions across four repos.

## Why this document exists

A shipped fix leaves a trace in the code. A rejected one leaves nothing, so it gets
re-proposed by the next person who notices the same symptom, and the argument gets had
again from scratch. Eleven build proposals were generated from real evidence and nine
were killed. Those nine are the expensive part of the review and the part that would
otherwise evaporate.

## The state of play the review established

This is the context every rejection below depends on, and it is the thing to re-check
before reversing any of them.

Walter works, and the evidence for that is thinner and duller than the project's own
documentation implies. Across the three production repos there were **four** PreToolUse
denials in total, and **two of those were false positives**. Eleven agent-issued `Done`
mutations succeeded in ShannonAndTheRiots immediately before a `Done` probe was denied.
Replaying the whole corpus against current source, **8 distinct legitimate commands out
of 2,467 would be denied today, and seven of the eight are inside walter's own repo**.

The defensible claim is that walter works as a **Stop-time backstop and a context
injector**. It is not demonstrated as end-to-end enforcement. The best outcome in the
corpus, automation-pal retiring an entire bridge-protocol write path (`decision-3`,
`superseded_by: decision-4`), was produced by empirical probes and human judgment, with
walter load-bearing only for recording and parking it. A convention did that work, not a
hook.

Net return on investment is **NOT ESTABLISHED**. The corpus contains no unmanaged control
sessions and no record of implementation or interruption cost.

## Rejected, with the objection that killed each

**Review-entry integrity gate.** A gate can only check that criteria exist, and the CLI
lets an agent remove or replace the criteria it wrote moments earlier. Self-grantable.
The incident offered as evidence (RIOTS-41) turned out on inspection to have had every
criterion checked, so the motivating example was not real either. This is the same
argument already recorded in `2026-08-25-acceptance-criteria-timing.md`, reached
independently from different evidence.

**Unconditional Review-consistency gate.** Would have blocked BD-25, which deliberately
left two obsolete criteria unchecked rather than falsely claim them. A gate that punishes
the honest move is worse than no gate.

**BD-29, prompting for uncaptured context at Stop.** Premise falsified: Stop is not a
session-end signal. One Riots-Vasco session received five Stop prompts between 09:49 and
10:16. Noted on the ticket directly so nobody builds it from the title.

**Enforcement-truth registry / runtime attestation.** Would verify that a hook is present,
which is not what varied. Eleven `Done` mutations succeeded in the same session as a
`Done` denial, so presence was never the question.

**Versioned onboarding upgrader, and separately "version and migrate the installed
contract".** Both refuted as already owned by BD-24, whose matching criterion is checked.
Note the sting: the criterion is checked and the contradiction is still live in two
production repos, because BD-24 fixed the plugin and never migrated the installed
instances. That gap is real and became BD-34; the *separate project* is what was rejected.

**One-adopter sequential value pilot.** Contract-first then walter-later is
order-confounded by learning, time, task mix and agent variation. No amount of metric
collection separates walter's effect from those, and no success threshold was defined.
Proving walter's value needs a different design than "use it and see".

**Quarantine parent.sh, and atomic board-confined bundling.** Both refuted for lack of an
observed data-loss incident. **This refutation was wrong and the fix shipped anyway.** See
below.

**BD-34's durable freshness mechanism** (config schema version plus a SessionStart staleness
check). Killed by both review lenses. The blocking defect: the check would be
**self-authenticating**. An agent could set `claim_gate` to false, render a matching
contract block, and obtain a "current" verdict with no human involvement. A drift detector
that an agent can satisfy by changing the policy is the precise failure that the `Pairing`
and subtask denials exist to prevent.

**BD-35's proposed matcher narrowing** (`\brm([^-]|$)`). Not a monotonic narrowing in
either direction: the character class can consume `;`, `|` or `&` and let the matcher cross
into the next command segment, and dropping the trailing word boundary newly matches any
word beginning with those letters. Worse, the relaxation is **agent-grantable**: a
hyphenated wrapper such as `rm-safe backlog/tasks/x.md` is caught by the current pattern
and would pass under the proposed one.

## Where the review was wrong

**The refuters were miscalibrated on latent defects**, and the prompt caused it. They were
told to default to refuted on weak evidence *and* to check whether the problem "actually
happens". For a latent corruption path those combine into "no incident yet, therefore not
real", which is not an engineering standard. `parent.sh` truncating a task file and
reporting success was killed on exactly that basis, then confirmed by direct inspection of
the source and fixed.

The rule that replaced it, used in the second review: *a latent defect is real whether or
not it has fired in production; equally, do not inflate a performance or cosmetic issue
into a safety one.* Both halves were needed. The same session also produced an
overstatement in the other direction, BD-33 being described as breaking fail-open when it
only costs cache hits.

**Identical refuters find identical things.** The first review ran ten clones, all applying
the same default, and none found an exploit. The second gave each design two distinct
lenses, one attacking the mechanism and one attacking the incentives. The
agent-grantable-wrapper defect above was found only by the incentives lens. Redundancy
buys confidence in a verdict; it does not buy coverage of failure modes.

## What was built, and why we stopped

Built: **BD-32** (parent.sh atomic rewrite) and **BD-33** (bash 3.2-safe array expansion),
both confirmed by direct inspection rather than by the review's ranking, both shipped with
suites verified to detect the defect they fix.

Not built, deliberately: everything above, plus BD-34's durable mechanism and BD-35's
matcher change.

The reasoning for stopping is the state of play. Nothing found is on fire. BD-32 never
fired in production. BD-33 costs cache hits on stock macOS only. BD-35 affects one repo,
whose task prefix `RM-` collides with a verb the guard word-matches, and only when a
command touches two or more task files. BD-34 is drift in repos that are demonstrably
working. Against that, every remaining change touches hooks that run on every session in
four repos.

The review was worth running as **diagnosis**. Its findings are captured here and on the
tickets. Converting more of them into code is where it starts costing more than it returns,
and the BD-34 design is the proof: left unchallenged it would have put a self-certifying
check into the one part of the system whose entire value is that it cannot be self-granted.

## What would reverse this

- A `parent.sh` or guard failure observed in a repo that is not walter's own.
- The false-positive rate rising outside walter's repo, or any denial of legitimate work in
  a production session.
- A second adopter, which changes the installed-base drift from an annoyance into a support
  burden and makes BD-34's mechanism worth reconsidering, though not in the rejected form.
- Evidence that criteria decay has spread to *planned* tasks, which is the reversal
  condition already recorded in `2026-08-25-acceptance-criteria-timing.md`.
