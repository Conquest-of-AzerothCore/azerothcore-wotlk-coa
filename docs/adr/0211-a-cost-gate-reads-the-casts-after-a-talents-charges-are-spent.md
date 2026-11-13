# 0211. A cost gate reads the casts after a talent's charges are spent

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0205 (cost-gate target health), ADR 0152 (cooldown gates)

## Context

Testament of Strength 300514, claim 20: "Your next 3 Titanstrikes incur a $s1% reduced cooldown". The cooldown gate
sets the aura afresh (3 charges, AscensionTemplarAuras.cpp:116-119) before each arm, so no arm reached a fourth
Titanstrike. A server that reduced every Titanstrike while 300514 lasts would have passed (review I2).

## Considered options

1. `setup_casts` of the gated spell before the priming cast. The setup does not reset the cooldown before the priming
   cast, so the priming cast itself would be refused.
2. A chain after the `with` arm, at the same wait and without a fresh aura. Chosen.

## Decision

`cost_gate` takes `charges` (a cooldown gate of a `talent_aura`, with no setup or after casts). After the `with` arm's
attempt, the gated spell is attempted again `charges` times, each at the arm's wait after the previous cast, with no
cooldown reset and no aura set. Casts 3 to `charges + 1` must go through, because the cast before each was still
reduced. Cast `charges + 2` must be refused, because the cast before it found no charge. Labels
`<spell> cost_gate <gated>[ <suffix>] cast_<n>`.

## Consequences

- Claim 20: casts 3 and 4 go through and cast 5 is refused (67). Only the first three Titanstrikes are reduced.
- Entries without `charges` regenerate byte-identical.
- Tests: `test_behaviours.CostGateChargeTests`. A fourth reduced cast alerts.
