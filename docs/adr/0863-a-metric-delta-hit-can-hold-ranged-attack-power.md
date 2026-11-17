# 0863. A metric delta hit can hold ranged attack power

- Status: accepted
- Date: 2026-11-16

## Context

Feast of Talons 500056 states the crows 500564 as `${...*($500564m1+$500564ppl1+$SP*.175+$RAP*0.1)}`. D-57 proves an
AP, RAP or SP term only by a hit with a contrast arm. `player_spell_power` (ADR 0364, ADR 0734) and
`player_attack_power` (ADR 0734) hold the spell power and the melee attack power; the harness player fixture also
reads `ranged_attack_power` (`CoAGameplayTest.cpp`, `HandleStatFlatModifier(UNIT_MOD_ATTACK_POWER_RANGED, ...)`), but no
`metric_delta` field sets it.

## Options

- Set the ranged attack power through `player_attack_power`: a different unit mod, the melee one.
- A harness change: the fixture already exists.
- An opt-in `metric_delta` option module that sets the existing player fixture.

## Decision

`player_ranged_attack_power`, a positive integer (D-293, category A): it sets `players[0].ranged_attack_power`
and adds a sentence to the contract.

## Consequences

- Test: `PlayerRangedAttackPowerTests` (metric_delta_options/test_player_ranged_attack_power.py), with a refusal for
  a non-positive or non-integer value.
- Only entries that set the option change; the Templar and Necromancer digests are unchanged.
