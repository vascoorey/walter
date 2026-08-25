export const meta = {
  name: 'walter-review',
  description: 'Evidence-grounded review of the walter plugin across four real repos, ending in a prioritised build recommendation',
  phases: [
    { title: 'Evidence' },
    { title: 'Candidates' },
    { title: 'Refute' },
    { title: 'Prioritise' },
  ],
}

const PACK = args.pack
const WALTER = args.walter
const REPOS = args.repos

// Every reader gets the same standing rules. The single most important one is that the
// walter corpus contains hook SOURCE and TEST OUTPUT that looks identical to hook
// firings; an agent that greps naively will overstate enforcement by ~10x.
const RULES = `
EVIDENCE RULES (binding)

You are reviewing "walter", a Claude Code plugin that enforces kanban board discipline
on coding agents. It is ~1000 lines of bash across 5 hooks plus one human-run script.

Ground truth available to you:
  - The plugin itself: ${WALTER}
  - Three repos really onboarded onto it: ${REPOS.join(', ')}
  - An extracted transcript+board evidence pack: ${PACK}
    READ ${PACK}/README.md FIRST. It documents the file formats and a contamination
    trap you must not fall into.

You have shell access (read-only). Use grep/sed/awk/jq over the pack and the repos.
Do not modify anything.

1. CITE OR LABEL. Every factual claim carries either a citation
   (file:line, or "repo session line" from the pack's TSVs) or the explicit prefix
   "INFERENCE:". A claim with neither is a defect in your output.
2. The walter corpus is contaminated. hooks/scripts/*.sh source text and scratch-suite
   output contain strings like "BLOCKED: ..." verbatim. Unexpanded shell variables
   ($STATUS, $PAIRING_STATUS) are the tell. Production-repo evidence outranks
   walter-repo evidence for any question about what actually happens.
3. Absence of evidence is a finding, not a licence to guess. If you cannot establish
   something, say "NOT ESTABLISHED" and say what you searched.
4. You have no web access. If a claim needs external/current facts (what competing
   tools do, what backlog.md supports in a version you cannot see), report it as a
   SOURCE GAP. Never invent a competitor, a feature, or a benchmark.
5. Do not recommend anything in this phase. Report what is.
`

const FINDINGS = {
  type: 'object', additionalProperties: false,
  required: ['lens', 'searched', 'findings', 'sourceGaps', 'notEstablished'],
  properties: {
    lens: { type: 'string' },
    searched: { type: 'string', description: 'what you actually grepped/read, so a reader can reproduce it' },
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['claim', 'evidence', 'confidence', 'soWhat'],
        properties: {
          claim: { type: 'string' },
          evidence: { type: 'string', description: 'citations, or the literal prefix INFERENCE:' },
          confidence: { type: 'string', enum: ['confirmed', 'probable', 'speculative'] },
          soWhat: { type: 'string', description: 'why this matters for what to build next' },
        },
      },
    },
    sourceGaps: { type: 'array', items: { type: 'string' } },
    notEstablished: { type: 'array', items: { type: 'string' } },
  },
}

phase('Evidence')

const LENSES = [
  {
    key: 'enforcement-reality',
    brief: `Establish the gap between what walter CLAIMS to enforce and what it DEMONSTRABLY does.

Read the contract (${WALTER}/CLAUDE.md, ${WALTER}/templates/claude-md-section.md) and every
hook in ${WALTER}/hooks/. Then establish, from the pack, how often each guard actually
fired in the three PRODUCTION repos (not walter itself). Distinguish real firings from
source text and test output. Report the real per-guard, per-repo counts.

Then the interesting question: for each rule the contract states, is it hook-enforced,
contract-only, or unenforceable? And where a rule is contract-only, is there evidence in
the transcripts of it being followed or violated? A rule nobody breaks may need no gate;
a rule silently violated every session is a hole.`,
  },
  {
    key: 'cheapest-legal-exit',
    brief: `For every gate walter imposes, work out the cheapest way an agent can satisfy it
without doing the work it is meant to force.

The repo's own design principle is "a relaxation you can grant yourself is not a gate"
and "make the honest exit the cheapest one". Audit whether walter lives up to it.

Concretely: the stop-gate (${WALTER}/hooks/scripts/stop-gate.sh), the Review transition's
acceptance-criteria + evidence requirement, the triage protocol, the human-gated columns,
the subtask denial. For each, name the cheapest legal exit and whether it is honest.

Then look for it happening. Search the pack for acceptance criteria written and checked in
one burst immediately before a Review transition, evidence notes that assert rather than
show, and Triage tasks created to discharge an obligation rather than to capture work.
${PACK}/05-board-state.txt has AC counts and timestamps per task across all four repos.`,
  },
  {
    key: 'robustness',
    brief: `Audit the shell itself. ~1000 lines across ${WALTER}/hooks/scripts/ and
${WALTER}/scripts/parent.sh.

The stated invariant is that hooks MUST fail open: a missing config, missing jq, missing
backlog CLI, or an unusual repo must never break a session. Find every path that could
violate it, hang, or misfire.

Specifically worth checking: quoting and word-splitting, unset variables under set -u,
regex over untrusted command strings (the guards inspect the agent's own Bash commands,
which is a self-blocking hazard), BSD vs GNU tool differences (this runs on macOS),
the /tmp state files and their collision/hygiene behaviour, and parent.sh's frontmatter
rewrite which is the only code here that can destroy user data.

Rank by blast radius: what is the worst thing that happens when each one goes wrong?`,
  },
  {
    key: 'adoption-seam',
    brief: `Walter has been installed on three real repos. Examine the seam between the
plugin and the humans and repos using it.

Compare the three production configs and contracts against what ${WALTER}/commands/onboard.md
currently produces and what ${WALTER}/templates/claude-md-section.md currently says. Find
every drift: config keys that exist in the plugin but not in the onboarded repos, free-text
notes standing in for real keys, columns the plugin now assumes that a repo lacks, contract
text that has moved on.

Then judge the upgrade path in onboard.md: if a repo onboarded weeks ago, does running it
again actually bring the repo current, and how would anyone know it needed to?

Also examine the human-run scripts (parent.sh, and the migration script onboard.md
generates). The pack may show a human hitting friction with these. Search for it.`,
  },
  {
    key: 'outcomes',
    brief: `The other lenses ask whether walter works. This one asks whether it was WORTH IT.

Establish what the workflow actually produced across the three production repos. Read
${PACK}/05-board-state.txt and the decision docs in each repo's backlog/decisions/.

Anchors to verify and explain, not to assume:
  - automation-pal's backlog/decisions/decision-3 is status:rejected, superseded_by
    decision-4: a whole write path was retired. Establish what caused that decision and
    whether any part of walter is load-bearing for it. Be honest if the answer is that a
    convention rather than a hook did the work.
  - Triage is the largest column in every production repo. Establish whether it functions
    as a capture buffer that drains, or as a graveyard. Use created vs updated dates and
    promotion events in the transcripts.
  - There are tasks stranded in In Progress and Review. Establish how long and why.

Then the hard question: separate the value walter delivers from the value the human would
have got anyway from being organised. What did the tooling do that discipline alone would not?`,
  },
]

const evidence = (await parallel(LENSES.map((l) => () =>
  agent(`${RULES}\n\nYOUR LENS: ${l.key}\n\n${l.brief}`, {
    label: l.key, phase: 'Evidence', schema: FINDINGS, timeoutMs: 1500000,
  })))).filter(Boolean)

log(`evidence: ${evidence.length}/${LENSES.length} lenses returned, ${evidence.reduce((n, e) => n + e.findings.length, 0)} findings`)

// Barrier is justified here and only here: a candidate proposal must see every lens AND
// the existing backlog, or it will re-propose tickets that already exist.
phase('Candidates')

const DIGEST = evidence.map((e) => `## Lens: ${e.lens}\nsearched: ${e.searched}\n` +
  e.findings.map((f) => `- [${f.confidence}] ${f.claim}\n  evidence: ${f.evidence}\n  so what: ${f.soWhat}`).join('\n') +
  (e.sourceGaps.length ? `\nsource gaps: ${e.sourceGaps.join('; ')}` : '') +
  (e.notEstablished.length ? `\nnot established: ${e.notEstablished.join('; ')}` : '')).join('\n\n')

const CANDIDATE = {
  type: 'object', additionalProperties: false,
  required: ['candidates'],
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['title', 'problem', 'evidence', 'proposal', 'existingTicket', 'cost', 'killsAnything'],
        properties: {
          title: { type: 'string' },
          problem: { type: 'string', description: 'the failure it removes, stated as something that happens' },
          evidence: { type: 'string', description: 'citations from the evidence phase or the corpus' },
          proposal: { type: 'string', description: 'concretely what gets built or changed' },
          existingTicket: { type: 'string', description: 'the Triage ticket id this maps to, or NEW' },
          cost: { type: 'string', enum: ['hours', 'a session', 'multiple sessions'] },
          killsAnything: { type: 'string', description: 'what existing capability this makes redundant, or NONE' },
        },
      },
    },
  },
}

const BACKLOG_CTX = `
The plugin's own board already holds these Triage tickets. Read their full text in
${WALTER}/backlog/tasks/ before proposing anything, and map each candidate to one of them
or explicitly to NEW. Re-proposing an existing ticket under a new name is the main failure
mode here.

  BD-11 pluggable kanban backend: let repos choose their board tool
  BD-17 board-grooming command that clusters tasks and proposes labels/milestones
  BD-23 contract: no legitimate route out of Triage when the human names the task
  BD-26 session-start: no-board branch so walter is not silent where scope has nowhere to go
  BD-27 guard-transitions: prior-art field required before a build-shaped task leaves Triage
  BD-28 doc sweep required when a task changed structure
  BD-29 stop-gate: prompt for uncaptured context before the session closes

Also read ${WALTER}/backlog/decisions/. Those decisions are binding. A candidate that
contradicts one is only valid if it argues explicitly for reversing it and says what
new evidence justifies that.
`

const [defectLed, valueLed] = await parallel([
  () => agent(`${RULES}\n\n${BACKLOG_CTX}\n\nEVIDENCE GATHERED:\n\n${DIGEST}\n\n` +
    `You are the DEFECT-LED proposer. Propose what to build next on the basis of what is
broken, dishonest, or load-bearing-but-unproven in the evidence above. Weight by blast
radius and by how often the evidence shows it actually biting. Ignore attractiveness.
Something that bites every session outranks something elegant.

Propose at most 6 candidates. Fewer, better ones are preferred. A candidate whose evidence
is only 'INFERENCE:' should not be proposed at all.`,
    { label: 'defect-led', phase: 'Candidates', schema: CANDIDATE, timeoutMs: 1500000 }),
  () => agent(`${RULES}\n\n${BACKLOG_CTX}\n\nEVIDENCE GATHERED:\n\n${DIGEST}\n\n` +
    `You are the VALUE-LED proposer. Everything above is a repo talking to itself. Ask
instead what would make walter worth a second person adopting, and what would make it
demonstrably better than the discipline it encodes.

Consider seriously that the honest answer may be that walter should do LESS: that some
gates should be deleted, that the highest-value work is proving the value it already has
rather than adding surface, or that a convention is outperforming a hook and the hook
should go. The repo's own principles say redundant friction blinds, and ask whether a
capability should exist before improving it. Apply that to walter itself.

Propose at most 6 candidates, including at least one deletion or simplification if the
evidence supports one.`,
    { label: 'value-led', phase: 'Candidates', schema: CANDIDATE, timeoutMs: 1500000 }),
])

const pool = [...(defectLed?.candidates || []), ...(valueLed?.candidates || [])]

// Dedup on normalised title, keeping the first. Plain code, not an agent.
const seen = new Set()
const unique = pool.filter((c) => {
  const k = c.title.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim()
  if (seen.has(k)) return false
  seen.add(k)
  return true
})
const MAX_VERIFY = 10
const toVerify = unique.slice(0, MAX_VERIFY)
if (unique.length > MAX_VERIFY) log(`NOTE: ${unique.length - MAX_VERIFY} candidates dropped before refutation (cap ${MAX_VERIFY})`)
log(`candidates: ${pool.length} proposed, ${unique.length} unique, ${toVerify.length} going to refutation`)

phase('Refute')

const VERDICT = {
  type: 'object', additionalProperties: false,
  required: ['title', 'verdict', 'reasoning', 'strongestObjection', 'whatWouldFalsify'],
  properties: {
    title: { type: 'string' },
    verdict: { type: 'string', enum: ['justified', 'weakened', 'refuted'] },
    reasoning: { type: 'string' },
    strongestObjection: { type: 'string' },
    whatWouldFalsify: { type: 'string', description: 'the observation that would prove this is not worth building' },
  },
}

const verdicts = (await parallel(toVerify.map((c) => () =>
  agent(`${RULES}\n\nYou are a REFUTER. Your job is to try to kill this proposal, not to
improve it. Default to 'refuted' when the evidence is weak: an unproven proposal that
survives here costs a session of the human's life.

PROPOSAL
  title: ${c.title}
  problem claimed: ${c.problem}
  evidence offered: ${c.evidence}
  proposal: ${c.proposal}
  maps to existing ticket: ${c.existingTicket}
  claimed cost: ${c.cost}

Go and check it against the actual repos and the evidence pack. Attack in this order:

1. Is the problem real and does it actually happen? Verify the cited evidence yourself.
   Citations that do not check out mean 'refuted'.
2. Is it already solved, or already ticketed and merely restated?
3. Does the proposed fix create a cheaper illegitimate exit than the one it closes, or
   add friction that duplicates an existing gate? The repo holds that redundant friction
   blinds and that a self-grantable relaxation is not a gate.
4. Does it contradict a binding decision in ${WALTER}/backlog/decisions/?
5. Is the cost estimate credible given the size of the codebase?

Return 'justified' only if it survives all five.`,
    { label: c.title.slice(0, 40), phase: 'Refute', schema: VERDICT, timeoutMs: 1500000 })
    .then((v) => (v ? { ...c, ...v } : null))))).filter(Boolean)

const survivors = verdicts.filter((v) => v.verdict !== 'refuted')
log(`refutation: ${verdicts.filter((v) => v.verdict === 'justified').length} justified, ` +
  `${verdicts.filter((v) => v.verdict === 'weakened').length} weakened, ` +
  `${verdicts.filter((v) => v.verdict === 'refuted').length} refuted`)

phase('Prioritise')

const PLAN = {
  type: 'object', additionalProperties: false,
  required: ['headline', 'stateOfPlay', 'ranked', 'nextAction', 'doNotBuild', 'uncertainty'],
  properties: {
    headline: { type: 'string', description: 'one sentence: the single most important thing this review found' },
    stateOfPlay: { type: 'string', description: 'honest assessment of where walter actually is, grounded in the production evidence' },
    ranked: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['rank', 'title', 'why', 'evidence', 'ticket', 'cost', 'risk'],
        properties: {
          rank: { type: 'integer' },
          title: { type: 'string' },
          why: { type: 'string', description: 'why it is at this rank specifically, relative to the ones above and below' },
          evidence: { type: 'string' },
          ticket: { type: 'string' },
          cost: { type: 'string' },
          risk: { type: 'string', description: 'what could make this the wrong call' },
        },
      },
    },
    nextAction: { type: 'string', description: 'the single thing to do first, concretely' },
    doNotBuild: { type: 'array', items: { type: 'string' }, description: 'refuted proposals and why, so they are not re-proposed later' },
    uncertainty: { type: 'array', items: { type: 'string' } },
  },
}

const REFUTED_TEXT = verdicts.filter((v) => v.verdict === 'refuted')
  .map((v) => `- ${v.title}: ${v.strongestObjection}`).join('\n') || '(none refuted)'

const plan = await agent(`${RULES}\n\nYou are writing the final prioritised recommendation.
You did not produce any of the material below, and you are not obliged to defend it.

EVIDENCE:\n\n${DIGEST}\n\nPROPOSALS THAT SURVIVED REFUTATION:\n\n${
  survivors.map((s) => `### ${s.title}  [${s.verdict}]  ticket:${s.existingTicket}  cost:${s.cost}
problem: ${s.problem}
proposal: ${s.proposal}
evidence: ${s.evidence}
strongest objection against it: ${s.strongestObjection}
what would falsify it: ${s.whatWouldFalsify}
kills: ${s.killsAnything}`).join('\n\n')}\n\nREFUTED (do not resurrect without new evidence):\n${REFUTED_TEXT}\n\n
Produce a ranked build order. Rules for the ranking:

- Rank by evidence strength times blast radius, not by novelty. A dull fix with confirmed
  production evidence outranks an elegant one supported by inference.
- Say why each item sits above the one below it. A list without that reasoning is useless.
- Include deletions and simplifications in the ranking as first-class items if any survived.
- 'stateOfPlay' must be honest about how thin the production enforcement evidence is, if
  the lenses found it thin. Do not flatter the project.
- 'doNotBuild' preserves the refutations so this work is not redone in three weeks.
- Anything resting on inference rather than citation goes in 'uncertainty', not in the ranking.

Rank every survivor. Do not silently drop any.`,
  { label: 'prioritise', phase: 'Prioritise', schema: PLAN, timeoutMs: 1800000 })

return {
  plan,
  survivors,
  refuted: verdicts.filter((v) => v.verdict === 'refuted'),
  evidence,
  counts: {
    lenses: evidence.length,
    findings: evidence.reduce((n, e) => n + e.findings.length, 0),
    proposed: pool.length,
    unique: unique.length,
    verified: verdicts.length,
    justified: verdicts.filter((v) => v.verdict === 'justified').length,
    refuted: verdicts.filter((v) => v.verdict === 'refuted').length,
  },
}
