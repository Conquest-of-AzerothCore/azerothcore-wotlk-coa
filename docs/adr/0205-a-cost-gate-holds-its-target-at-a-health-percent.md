# 0205. A cost gate holds its target at a health percent

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0137 (cost gates), ADR 0152 (cooldown gates on the accelerated cap)

## Context

Testament of Strength 300514, claim 20: "Your next 3 Titanstrikes incur a $s1% reduced cooldown". Titanstrike
806521 needs its target below 20% health (TargetAuraState 13). The `without` arm of a cooldown gate, at a
full-health dummy, was refused for the health state, not for the cooldown, so it could not be the control.

## Considered options

1. Rely on 300514's Effect[2] (ignore the aura state) in every arm. The control arm has no 300514.
2. A cost-gate field that lowers the dummy's health before the arms, as `hit_ratio` does. Chosen.

## Decision

`cost_gate` takes `target_health_pct` (the dummy only, 1-99): one `set_health_pct` and the settle wait of `hit_ratio`
after the learns. The contract states it.

## Consequences

- Claim 20: refused (67) 4500 ms after the priming cast without 300514, through with it, refused 3500 ms after it.
- Entries without the field regenerate byte-identical (1693 of 1693 for ADRs 0204-0208 together, 11 new scenarios).
- Tests: `test_behaviours.CostGateTargetHealthTests`.
