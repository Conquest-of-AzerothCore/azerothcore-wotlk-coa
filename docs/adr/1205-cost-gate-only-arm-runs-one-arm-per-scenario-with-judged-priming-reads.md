# 1205. Cost gate `only_arm` runs one arm per scenario, with judged `priming_reads`

- Status: proposed (provisional number, renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 1204](1204-cost-gate-extra-reads-are-diagnostic-readings-after-the-attempt.md),
  [ADR 1203](1203-cost-gate-refused-with-post-trigger-casts-and-a-threat-slope-flat.md) (opt-in cost gate fields).
- Decided by: mentor D-194 (Sun Cleric 805581 c361, recast behaviour proof).

## Context

A `cost_gate` entry builds every arm (`without`, `with`, `beyond`, ...) in one scenario. For Trial of Valor 805581 the
arms leaked into each other: the Dawn and Vow of Grace auras a previous arm left up made the recast accepted in the
`with` arm only (D-190, D-191), so the recast of Horusath Blast 500154 could not be attributed to the Vow fulfilment
of its own arm. `metric_delta` has no recast step, so no existing kind could attempt the recast in an isolated arm.

## Options

- A new kind or a new harness step. Rejected: the steps, the attempt and the judge are those of `cost_gate`.
- A field that generates several scenarios from one entry. Rejected: the generator maps one entry to one scenario.
- An opt-in field of `cost_gate` selecting one arm per entry, absent by default.

## Decision

- `cost_gate` field `only_arm`: one of `without`, `with`, `beyond`, `unfulfilled` on a plain cooldown gate (no resets,
  longer cooldown, `next_arm`, `unset_arm`, duration arm, `talent_aura`, `charges` or `removal_wait_ms`). The scenario
  holds that arm alone and its name ends with the arm; labels keep the form `<spell> cost_gate <gated> <suffix> <arm>`.
  `unfulfilled` is the `with` arm (talent learned, the entry's `setup_casts` cast) expected refused: the entry's
  `setup_casts` leave out the fulfilling cast.
- `cost_gate` field `priming_reads`: a list of `{"spell", "expected"}` (expected 0 or 1). Each is an aura read on the
  caster right before the priming cast of the gated spell, judged exactly against `expected` as a precondition check.
- Both are off by default.

## Consequences

- Digests of classes 15, 19, 19 `--stack` and 23 were regenerated before and after and are byte-identical.
- Seeded tests (`OnlyArmTests`) cover the off default, one arm per scenario, the learned talent per arm, the wait of
  the beyond arm, the placement and judging of the priming reads and the refusals.
