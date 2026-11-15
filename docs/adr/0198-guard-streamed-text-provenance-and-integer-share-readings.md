# 0198. Guard streamed-text provenance and integer share readings

- Status: accepted
- Date: 2026-11-12
- Supersedes: the claim 188 part of ADR 0190's consequences, and the provenance paragraph of ADR 0192's decision
  (prose only, now enforced).

## Context

The first review of ext2 (lean/ext2-review.md) found:
- I1: claim 188 (Calm Combatant 705281) reads combat_rating 0 to 16 from Intellect 32 x 50%; +51% truncates to the
  same 16 (`int32(CalculatePct(...))`, PlayerUpdates.cpp:667-668). The stat-passives ruling of 2026-11-11 keeps such a
  clause data conformant.
- I2: the independence condition for streamed texts lived only in the docs.
- I3: a `text_correction` basis was exempt without a check that the claim's figures are unchanged.
- M1: the flat-reduction verdict gave neither the control strike nor the reductions it excludes.

## Decision

- A `passive_delta` share reading of an integer metric whose stated percent and a 1% neighbour truncate to the same
  value carries `data_only` (`compare.share_neighbour_reason`).
- Coverage refuses (`EvidenceError`) a ledger entry whose spell has a streamed row but no `text_source`, or whose basis
  is not one of `owner_ruling`, `live_source`, `text_correction`, `align_to_server`.
- A claim whose `dbc_clause` differs from its clause counts only when its basis is `owner_ruling` or `live_source`, or
  `text_correction` with every number, `$` token and colour-named spell identical in the two (`streamed.figures`).
  Otherwise it is counted unproven and listed as judged against a project-written text.
- The flat-reduction verdict prints the control strike, the accepted damage range and the reductions the strikes fit,
  and is `unmeasured` when those reductions reach beyond the band.

## Consequences

- 188 is data conformant by the stat-passives ruling (status 2); the coverage moves from 245 to 244 behaviour.
- 147 counts: "Only occurs once every 0.5 sec." and the DBC "Cnly occur once every 0.5 sec." share the figure 0.5.
  The other 15 claims with a streamed source rest on owner rulings.
- Untainted's verdict now reads: control 64, accepted 47-48, reductions 16-17 against 17 (band +-2).
- Tests: `test_compare.ShareNeighbourTest`, `test_coverage.StreamedTextSourceTest`.
