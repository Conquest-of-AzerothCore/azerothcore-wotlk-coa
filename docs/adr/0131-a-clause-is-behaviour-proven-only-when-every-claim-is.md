# 0131. A clause is behaviour proven only when every claim is

- Status: accepted
- Date: 2026-11-11
- Supersedes in part: ADR 0123 (the sentence "A proven entry with declared claims is behaviour proven when one of
  its claims is")

## Context

ADR 0120 gave clause coverage two proof statuses, and ADR 0123 made a clause with declared `claims` proven only when
every claim is. ADR 0123 kept the earlier rule for the status of a proven clause: behaviour proven when one claim is
behaviour proven, and left the stricter rule as an owner question. The owner ruled on 2026-11-11
(`owner-rulings-2026-11-10.md`, "Lean package follow-up rulings"): a clause counts as behaviour proven only when
every claim of it is proven in game; otherwise it is data conformant.

## Considered options

1. Keep "one behaviour claim is enough". Rejected by the ruling: a clause whose duration is shown in game and whose
   amount is only read back would count as behaviour proven.
2. Behaviour only when every claim is behaviour; also require every label of one claim to be behaviour. Rejected:
   the labels of one claim all measure that claim (an entry whose labels measure several stated claims declares
   them, ADR 0123), and a readback beside an in-game measurement of the same value does not weaken it.
3. Behaviour only when every claim is behaviour; a claim keeps ADR 0120's rule over its labels. Chosen.

## Decision

- `coverage.claims_evidence`: unproven when one claim is unproven, behaviour when every claim is behaviour, data
  otherwise.
- An undeclared entry is one claim, so its status is unchanged.

## Consequences

- A clause with one behaviour claim and one data claim moves from behaviour to data. Fragments write the clause row
  with the new status and keep each claim's own status.
- Seeded test: `test_coverage.DeclaredClaimsTest.test_seeded_mixed_proof_is_data_and_every_claim_in_game_is_behaviour`
  fails under the old rule.
