# 1171. A dummy can cast at the caster after a self-cast trigger

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 1112

## Context

Hexing Effigy 506634 "The next enemy that casts a spell on you is transformed into a frog": the Effigy hook
(AscensionWitchDoctorSummons.cpp:666-686) acts on a non-triggered harmful cast whose unit target is the Effigy's
owner. `dummy_casts_at_caster` sends exactly that cast, but required the trigger to target the dummy, while the
Effigy is cast at the caster (tool note T-b18-1).

## Decision

`dummy_casts_at_caster` also accepts a trigger cast at the caster when the entry reads the dummy (`measure_actor` or
`fields.target`) or selects it, so the dummy is in the scenario. Its optional `"target": "ally"` casts at the
`grouped_ally` of ADR 1174 instead.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical (the contract
text of a caster target is unchanged). Class 13 gains 506634 `effigy_frogs_caster` and 800330 `golem_redirect`.
