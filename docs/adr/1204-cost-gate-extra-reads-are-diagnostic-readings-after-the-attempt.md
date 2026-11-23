# 1204. Cost gate `extra_reads` are diagnostic readings after the attempt

- Status: proposed (provisional number, renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 1203](1203-cost-gate-refused-with-post-trigger-casts-and-a-threat-slope-flat.md) (opt-in cost gate fields),
  [ADR 0582](0582-metric-delta-options-are-modules.md).
- Decided by: mentor D-189 (Sun Cleric 805581 c361, targeted measurement D-188).

## Context

Trial of Valor 805581 reads Horusath Blast's own cooldown at 0 while the recast is still refused (cast_failure 67).
`cost_gate` ends its attempt with the single read `cast_failure`, and `metric_delta` reads one metric per trial, so
the cooldown of every rank id, the global cooldown, the power and the fixture auras could not be read at the instant
of the refusal.

## Options

- A new harness metric. Rejected: every needed metric exists (`cooldown_ms`, `global_cooldown_ms`, `knows_spell`,
  `aura`, `power`).
- A new kind. Rejected: the arms, setup and attempt are the ones of `cost_gate`.
- An opt-in field of `cost_gate`, absent by default, so every existing scenario regenerates byte-identical.

## Decision

- `cost_gate` field `extra_reads`: a list of `{"metric", "spell"}` (`power` takes no spell and reads the power type
  of the gated spell). Metrics: `cooldown_ms`, `global_cooldown_ms`, `knows_spell`, `aura`, `power`.
- The reads are unbounded assert steps right after the attempt's `cast_failure` read, in the `without` and `with`
  arms only, labelled `<arm label> extra <metric> [<spell>]`.
- They are diagnostic: recorded in the result's steps, never an expectation, never a label of the ledger, they cannot
  lift a claim or change a verdict.

## Consequences

- Digests of classes 15, 19, 19 `--stack` and 23 were regenerated before and after and are byte-identical.
- A seeded test (`ExtraReadsTests`) covers the off default, the placement, the absence of expectations and the
  refusal of an unknown metric.
