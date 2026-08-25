export const meta = {
  name: 'bd34-35',
  description: 'Establish the facts behind BD-34 (claim_gate drift across onboarded repos) and BD-35 (guard false positives), and produce a verified migration and fix plan',
  phases: [
    { title: 'Establish' },
    { title: 'Design' },
    { title: 'Refute' },
    { title: 'Land' },
  ],
}

const W = args.walter
const PACK = args.pack
const REPOS = args.repos

const RULES = `
You are working on "walter", a Claude Code plugin enforcing kanban board discipline.
Plugin source: ${W}
Repos really onboarded onto it: ${REPOS.join(', ')}
Extracted transcript + board evidence pack: ${PACK} (read ${PACK}/README.md first)

You have read-only shell access. Use grep/sed/awk/jq/git. Do not modify anything.

RULES
1. CITE OR LABEL. Every factual claim carries a citation (file:line, or
   "repo session line" from the pack TSVs) or the literal prefix "INFERENCE:".
2. The walter corpus contains hook SOURCE and TEST OUTPUT that looks exactly like
   hook firings. Unexpanded shell variables ($STATUS, $PAIRING_STATUS) are the tell.
   Production-repo evidence outranks walter-repo evidence for what actually happens.
3. Absence of evidence is a finding. Say "NOT ESTABLISHED" and say what you searched.
4. Re-read the artifact, never a summary of it. Where a doc and the code disagree,
   the code wins and the doc is a finding.
5. A latent defect is real whether or not it has fired in production. Do not dismiss
   a correctness problem for lack of an observed incident. Equally, do not inflate a
   performance or cosmetic issue into a safety one: state the measured blast radius.
`

const FACTS = {
  type: 'object', additionalProperties: false,
  required: ['topic', 'searched', 'facts', 'notEstablished'],
  properties: {
    topic: { type: 'string' },
    searched: { type: 'string' },
    facts: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['statement', 'evidence', 'confidence', 'consequence'],
        properties: {
          statement: { type: 'string' },
          evidence: { type: 'string' },
          confidence: { type: 'string', enum: ['confirmed', 'probable', 'speculative'] },
          consequence: { type: 'string', description: 'what breaks or misleads because of this' },
        },
      },
    },
    notEstablished: { type: 'array', items: { type: 'string' } },
  },
}

phase('Establish')

const PROBES = [
  {
    key: 'bd35-does-bd18-cover-it',
    brief: `BD-35. The review established that of four real PreToolUse denials across the three
production repos, two were false positives: a Riots-Vasco denial blocked a read-only
'backlog task list' filtered by Done, and a Shannon task-file denial fired on a command
that was not a write.

BD-18 ("guard-transitions blocks read-only board queries") was supposed to have closed the
read-only case and is currently in Review. Settle these, in order:

1. Find the two false-positive commands verbatim in the pack. Quote the exact command
   strings and their citations.
2. Read the CURRENT ${W}/hooks/scripts/guard-transitions.sh and lib/board.sh. Determine by
   reading the regexes whether each of those exact command strings would still be denied
   today. Do not guess from the ticket text: trace the actual matching.
3. Establish whether the transcripts predate the BD-18 fix. Use git log on the plugin and
   the transcript timestamps.
4. If a case is still live, characterise the class, not just the instance: what shape of
   legitimate command still trips the guard?

Also count how many DISTINCT legitimate commands in the whole pack would be denied by the
current guards if replayed today. That number is the real false-positive rate and nobody
has it.`,
  },
  {
    key: 'bd34-drift-inventory',
    brief: `BD-34. Produce a complete, exact inventory of configuration and contract drift between
what walter ships today and what the three onboarded repos actually contain.

For EACH of the three repos, compare against the current ${W}/commands/onboard.md,
${W}/templates/claude-md-section.md and every hook that reads config:

  - .board/config.json: every key present, every key the hooks read that is missing, and
    every free-text key standing in for a real one (claim_gate_note, notes, and any others).
  - backlog/config.yml statuses versus the columns the hooks now assume exist.
  - the repo's CLAUDE.md board section versus the current template: which rules are stale,
    which are absent, which contradict a hook's actual behaviour.

Be exhaustive and exact. This inventory is the input to a migration, so a missed key is a
repo left broken. For each drift item state what the hook does TODAY in that repo as a
result, citing the hook line that reads the key.`,
  },
  {
    key: 'bd34-upgrade-path-reality',
    brief: `BD-34, second half. Judge whether walter can currently repair its own installed base.

Read ${W}/commands/onboard.md's upgrade path closely, especially its detection predicates:
what exactly does it test to decide a repo needs upgrading, and what does it then change?

Establish:
1. Run mentally against each of the three real repos: for each, would the current upgrade
   path detect the drift the inventory found, and would it repair it? Answer per repo, per
   drift item. Cite the predicate line and the repo state it tests against.
2. Where it would silently do nothing, say so explicitly. A no-op that reports success is
   worse than an error.
3. Is there ANY mechanism by which an onboarded repo learns it is out of date? Search the
   hooks for a version check, a schema check, or a warning. If none exists, say so.
4. The pack may show a human hitting friction with the generated migration script
   (a missing executable bit is documented). Find any other human-facing failures in the
   onboarding or upgrade flow and cite them.`,
  },
]

const facts = (await parallel(PROBES.map((p) => () =>
  agent(`${RULES}\n\nPROBE: ${p.key}\n\n${p.brief}`, {
    label: p.key, phase: 'Establish', schema: FACTS, timeoutMs: 1500000,
  })))).filter(Boolean)

log(`established: ${facts.length}/${PROBES.length} probes, ${facts.reduce((n, f) => n + f.facts.length, 0)} facts`)

const DIGEST = facts.map((f) => `## ${f.topic}\nsearched: ${f.searched}\n` +
  f.facts.map((x) => `- [${x.confidence}] ${x.statement}\n  evidence: ${x.evidence}\n  consequence: ${x.consequence}`).join('\n') +
  (f.notEstablished.length ? `\nNOT ESTABLISHED: ${f.notEstablished.join('; ')}` : '')).join('\n\n')

phase('Design')

const PLAN = {
  type: 'object', additionalProperties: false,
  required: ['ticket', 'approach', 'changes', 'rejected', 'verification', 'risks'],
  properties: {
    ticket: { type: 'string' },
    approach: { type: 'string', description: 'the shape of the fix in a few sentences' },
    changes: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['file', 'change', 'rationale'],
        properties: {
          file: { type: 'string' },
          change: { type: 'string', description: 'concretely what edit, precise enough to implement from' },
          rationale: { type: 'string' },
        },
      },
    },
    rejected: { type: 'array', items: { type: 'string' }, description: 'designs considered and why they lose' },
    verification: { type: 'array', items: { type: 'string' }, description: 'assertions that would prove it, each one falsifiable' },
    risks: { type: 'array', items: { type: 'string' } },
  },
}

const DESIGN_RULES = `
Design constraints, drawn from this repo's binding decisions in ${W}/backlog/decisions/
and its own stated principles. Violating one silently is a defect in your design.

- Hooks fail open. Missing config, missing jq, missing backlog CLI, an odd repo: none may
  break a session.
- A relaxation the agent can grant itself is not a gate. Work out your design's cheapest
  legal exit and make sure the honest one is cheapest.
- Redundant friction blinds. If a proposed gate duplicates an upstream check, drop it.
- Prefer data over branches: behaviour a repo might customise belongs in config, not in an
  enum in a hook.
- macOS ships bash 3.2. Empty-array expansion under set -u aborts there.
- Agents may not write task files. Anything touching a task file is human-run.
- Do not propose a gate whose only check is that something EXISTS when the property worth
  having is that it constrained the work. That argument is already recorded and binding.
`

const designs = (await parallel([
  () => agent(`${RULES}\n\n${DESIGN_RULES}\n\nESTABLISHED FACTS:\n\n${DIGEST}\n\n` +
    `Design the fix for BD-35: the guards' false positives. Read the current guard source
before proposing anything. Your design must state what shape of legitimate command stops
being denied, and must not open a hole through which a genuine violation passes. Give the
exact regex or logic change, not a description of one.

If the honest finding is that the observed cases are ALREADY fixed and BD-35 needs only a
verification pass plus a note, say that and design that instead. Do not invent work.`,
    { label: 'design:bd35', phase: 'Design', schema: PLAN, timeoutMs: 1500000 }),
  () => agent(`${RULES}\n\n${DESIGN_RULES}\n\nESTABLISHED FACTS:\n\n${DIGEST}\n\n` +
    `Design the fix for BD-34: the claim_gate contradiction and the wider config/contract
drift in the installed base.

Two things need designing and they are separable, so treat them separately:
  (a) the one-off repair of the three existing repos, which touches files agents may not
      write and so must end as something the human runs;
  (b) the durable mechanism that stops the installed base drifting silently again. Consider
      a config schema version, a SessionStart warning when the installed contract predates
      the plugin, or deciding that no mechanism is worth it and saying why.

For (b), apply the repo's own test: does it catch a failure mode no other check catches?
If your answer is that (b) should not be built, argue that and design only (a).`,
    { label: 'design:bd34', phase: 'Design', schema: PLAN, timeoutMs: 1500000 }),
])).filter(Boolean)

phase('Refute')

const VERDICT = {
  type: 'object', additionalProperties: false,
  required: ['ticket', 'verdict', 'defects', 'strongestObjection'],
  properties: {
    ticket: { type: 'string' },
    verdict: { type: 'string', enum: ['sound', 'needs-revision', 'broken'] },
    defects: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['defect', 'severity', 'fix'],
        properties: {
          defect: { type: 'string' },
          severity: { type: 'string', enum: ['blocking', 'serious', 'minor'] },
          fix: { type: 'string' },
        },
      },
    },
    strongestObjection: { type: 'string' },
  },
}

// Two distinct lenses per design rather than N identical skeptics: these designs can fail
// as correctness OR as workflow, and redundancy would not catch both.
const LENSES = [
  ['correctness', `Attack the mechanism. Trace the proposed regex or logic against real command
strings from the pack and against the repo's actual files. Does it do what it claims? Does it
break a case that currently works? Does it survive bash 3.2, a missing lib, a repo with
different column names? Find a concrete input where it misbehaves.`],
  ['goodhart', `Attack the incentives. What is the cheapest legal way for an agent to satisfy
this design without doing the work it exists to force? Is the relaxation agent-grantable? Does
it duplicate an existing gate, making both less legible? Would it train a false claim? Judge
it against the binding decisions in ${W}/backlog/decisions/ and say which one it violates.`],
]

const verdicts = (await pipeline(
  designs,
  (d) => parallel(LENSES.map(([lens, brief]) => () =>
    agent(`${RULES}\n\nYou are reviewing a design you did not write. Do not improve it; find
what is wrong with it. Verdict 'sound' only if you genuinely cannot break it.

LENS: ${lens}
${brief}

DESIGN FOR ${d.ticket}
approach: ${d.approach}
changes:
${d.changes.map((c) => `  - ${c.file}: ${c.change}\n    rationale: ${c.rationale}`).join('\n')}
rejected alternatives: ${d.rejected.join('; ') || '(none stated)'}
proposed verification: ${d.verification.join('; ')}
stated risks: ${d.risks.join('; ') || '(none stated)'}`,
      { label: `${lens}:${d.ticket}`.slice(0, 40), phase: 'Refute', schema: VERDICT, timeoutMs: 1500000 })))
    .then((vs) => ({ design: d, reviews: vs.filter(Boolean) })),
)).filter(Boolean)

log(`refute: ${verdicts.map((v) => `${v.design.ticket}=${v.reviews.map((r) => r.verdict).join('/')}`).join(' ')}`)

phase('Land')

const FINAL = {
  type: 'object', additionalProperties: false,
  required: ['summary', 'perTicket', 'sequence', 'openQuestions'],
  properties: {
    summary: { type: 'string' },
    perTicket: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['ticket', 'verdict', 'whatToDo', 'changes', 'verification', 'humanRun'],
        properties: {
          ticket: { type: 'string' },
          verdict: { type: 'string', description: 'build as designed, build revised, or do not build and why' },
          whatToDo: { type: 'string' },
          changes: { type: 'array', items: { type: 'string' } },
          verification: { type: 'array', items: { type: 'string' } },
          humanRun: { type: 'string', description: 'anything the human must run themselves, or NONE' },
        },
      },
    },
    sequence: { type: 'array', items: { type: 'string' }, description: 'the order to do it in, and why that order' },
    openQuestions: { type: 'array', items: { type: 'string' }, description: 'decisions that are the human\'s, not yours' },
  },
}

const final = await agent(`${RULES}\n\nYou are consolidating. You wrote none of this and owe it no loyalty.

ESTABLISHED FACTS:\n\n${DIGEST}\n\nDESIGNS AND THEIR REVIEWS:\n\n${
  verdicts.map((v) => `### ${v.design.ticket}
approach: ${v.design.approach}
changes:
${v.design.changes.map((c) => `  - ${c.file}: ${c.change}`).join('\n')}
verification: ${v.design.verification.join('; ')}

reviews:
${v.reviews.map((r) => `  [${r.ticket}] ${r.verdict} — ${r.strongestObjection}
${r.defects.map((d) => `    (${d.severity}) ${d.defect}\n      fix: ${d.fix}`).join('\n')}`).join('\n')}`).join('\n\n')}

Produce the landing plan. Rules:

- Fold every BLOCKING and SERIOUS defect into the revised design, or state explicitly why
  the reviewer is wrong. Do not pass a known-broken design through.
- If a ticket turns out to need no code, say "do not build" and say what to record instead.
  That is a legitimate and often correct outcome.
- 'verification' items must be falsifiable assertions someone could write as a test, not
  aspirations. Each should name the input and the expected result.
- 'humanRun' matters: agents cannot write task files or edit another repo's board, so any
  migration touching the three production repos ends as a command the human runs.
- 'openQuestions' is for genuine judgment calls that belong to the human. Do not park
  technical decisions there to avoid making them.`,
  { label: 'land', phase: 'Land', schema: FINAL, timeoutMs: 1800000 })

return { final, designs, verdicts, facts, counts: { probes: facts.length, designs: designs.length } }
