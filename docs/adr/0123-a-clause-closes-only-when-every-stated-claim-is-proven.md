# 0123. A clause closes only when every stated claim is proven

- Status: accepted
- Date: 2026-11-11

## Context

The prototype review found I2 (prototype `score.md` §7): a ledger row closed a whole clause on a partial or weaker
proof. Duty Calls [705286] "increases your damage dealt and movement speed by $560834s1%" was closed by its speed
half alone; Absolution [800424] by its speed while its duration stayed unmeasured. The owner's fix order of
2026-11-11: a clause is closed only when every stated claim is proven; otherwise the row is per claim and the clause
counts as unproven.

In the lean ledger (`classes/<name>_clauses.json`) an entry is proven when all its labels are conformant, so the
same defect appears wherever an entry's labels measure only part of what its words state. An audit of the Templar
entries counted proven on round 10 (`templar-run2`) found 11 such entries, for example Norgannon's Wrath [524739]
"reduces their damage and healing done by $520842s1% for $520842d": 520842 holds the damage in e0 (aura 79,
`SPELL_AURA_MOD_DAMAGE_PERCENT_DONE`) and the healing in e1 (aura 136, `SPELL_AURA_MOD_HEALING_DONE_PERCENT`), and
the entry's labels read e0 and the duration only.

## Considered options

1. Split every such entry into several ledger entries. Rejected: the entry's `(spell, clause)` is the key fragments
   merge on, and split entries would each be counted as a clause.
2. Derive the claims from the tooltip tokens in code. Rejected: mapping tokens to labels is a heuristic the ledger
   should not depend on, and literal numbers ("40%", "8 yds") and one value moving two effects are not tokens.
3. Let an entry declare its stated claims (`claims`, each with its words and labels, at least two, in place of the
   entry's labels); an entry without `claims` keeps its labels as one claim. Chosen.

## Decision

- `coverage.clause_claims` returns an entry's claims; `require_claims` refuses a declaration with clause labels, on a
  `no_claim` entry, with fewer than two claims, or with a malformed claim (`EvidenceError`).
- An entry is proven only when every claim is proven. A claim's evidence follows the existing rule (behaviour when one
  of its matched verdicts is behaviour evidence, ADR 0120), with a state read judged against the claim's own words.
  A proven entry with declared claims is behaviour proven when one of its claims is, the same rule as for the labels
  of an undeclared entry. `ClauseCoverage.claim_evidence` holds each claim's status.
- Fragments (`fragment_entries`, `prove --clauses`): an entry whose claims are all proven gives one row with its
  `claims`; otherwise one row per claim (`claim`, `labels`, `evidence`), merged on `(spell, clause, claim)`, which
  never closes the clause. `prove` reads a row's labels from its claims.
- Templar: 92109, 300504, 524739, 560835 (burst), 680399, 681483, 705286, 705306, 800424, 806522 and 807814 declare
  their claims, each claim citing only verdict labels of round 10 that measure it.

## Consequences

- On round 10 `templar-run2` (and `templar`), clause coverage goes from 130 behaviour / 140 data / 163 unproven to
  125 / 137 / 171 of 433 claim entries.
- Whether a clause with one behaviour-proven claim and one data-conformant claim should count as behaviour proven is
  left as it was for undeclared entries; a stricter rule (behaviour only when every claim is) is an owner question.
- Entries whose other claims have their own ledger entries (Righteous Custodian 572808, High General 805415,
  Righteous Tempest 805409) are left undeclared: their siblings already prove each claim.
