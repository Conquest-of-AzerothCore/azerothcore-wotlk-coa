# 0127. A tool gap is resolved only after a second attempt or an owner acceptance

- Status: accepted
- Date: 2026-11-11

## Context

The prototype review (prototype `score.md` §7, I4) found tool gaps used for entry defects: two gaps one arm
declared were disproved by another arm (G1 N10 "no fixture forces a crit", G4 N4), and the cost figures counted a
tool gap as a resolved clause. The mentor's package (`mentor-review-g6.md`, "Package") adds: a tool gap counts as
resolved only after a second attempt by another agent or an explicit owner acceptance. The owner ruled the lean
method carries that rule (`owner-rulings-2026-11-10.md`, "Prototype score (G6) rulings"). The lean ledger had no
place to record a tool gap: an entry was `claim` or `no_claim`, and the coverage report counted proven clauses only.

## Considered options

1. Record tool gaps in round reports only. Rejected: the coverage figure and the cost denominator could not tell an
   unchecked gap from a cross-checked one.
2. A new ledger `kind: "tool_gap"`. Rejected: it would drop the clause from the claim denominator, as `no_claim`
   does.
3. An optional `tool_gap` on a claim entry, with its attempts and an optional owner acceptance; the coverage
   computes its state. Chosen.

## Decision

- A `claim` entry may carry `tool_gap: {"reason", "attempts": [{"agent", "report"}], "owner_acceptance"?:
  {"ruling"}}`. `coverage.require_tool_gaps` refuses a malformed one.
- `coverage.tool_gap_state`: `accepted` when two attempts name different agents or an owner acceptance is given,
  otherwise `pending`. The clause stays unproven either way.
- `ClauseCoverage.tool_gaps` lists the unproven clauses with a gap; `resolved = proven + accepted tool gaps`. The
  `coverage --clauses` report prints the accepted and pending counts, `clauses resolved` and each gap with its
  state; `prove` writes `tool_gaps_accepted`, `tool_gaps_pending` and `resolved` per run.
- Fragment rows of an unproven clause carry its `tool_gap` and `tool_gap_state`; the integrator appends attempts.

## Consequences

- A cost per resolved clause counts a tool gap only once it passed this rule; a pending gap stays in the
  denominator as unresolved.
- The behaviour and proven figures are unchanged by a tool gap.
- No Templar ledger entry declares a tool gap yet; the first batch records its gaps this way.
