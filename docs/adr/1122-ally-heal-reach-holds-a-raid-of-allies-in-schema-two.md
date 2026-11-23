# 1122. Ally heal reach holds a raid of allies in schema 2

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1021 (`ally_heal_reach`)

## Context

Healing Ward 500957 heals "8 nearby allies": its AI heals the first 8 of Allies(player, me, 30, 8) by health percent
(AscensionWitchDoctorSummons.cpp:493-497). A cap of 8 shows only with a ninth candidate, and schema 1 holds 8 players
with the caster, so `ally_heal_reach` stopped at 7 allies (cycle 7 no-route note T-ally).

## Decision

`ally_heal_reach` accepts up to 24 allies. With more than 7 the scenario is schema 2 (25 players, as `run.py` and
`CoAGameplayTest.cpp` already allow); with 7 or fewer it stays schema 1.

## Consequences

- No existing entry has more than 7 allies, so classes 19 (with and without `--stack`) and 23 generate byte-identical
  scenarios; the test that refused an eighth ally now checks the schema switch and refuses a 25th.
- Witch Doctor 500957 `ward_cap`: eight allies at 10% health are healed, a ninth at 60% is not.
