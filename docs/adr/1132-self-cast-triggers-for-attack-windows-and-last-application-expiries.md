# 1132. Self-cast triggers for attack windows and last-application expiries

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1027 (target_attack_window), ADR 0593 and ADR 0716 (last_application_expiry)

## Context

Death Draught 602220 ("which may trick enemies into ignoring you") is a self cast, and The True Spirit 802268's buff
comes from a Serpent Ward 500960 summon, a self-range spell. `target_attack_window` refused a trigger at the caster,
and `last_application_expiry` always cast its trigger at the dummy.

## Decision

`target_attack_window` accepts the caster as the trigger target (the read stays the dummy's swings at the caster).
`last_application_expiry` takes an optional `trigger_target` (`dummy` by default, or `caster`).

## Consequences

Absent fields keep every existing scenario. Opt-in only; generated scenarios of classes 19 (with and without
`--stack`) and 23 are byte-identical. Class 13 gains 602220 `draught_ignored` and 802268 `true_lasts`.
