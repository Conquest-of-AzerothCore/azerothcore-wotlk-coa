# 0210. A script hit read with stat auras set before the stats are measured

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0160 (script-cast hits), ADR 0209 (Divine Charge's trample)

## Context

The regression for ADR 0209 needs a control arm with no attack power or spell power bonus, so that the trample's base
term ($527270m3 + $527270ppl3) is read alone. The script-hit model reads the caster's stats from the base
measurements, which run before any `caster_auras`. A script-hit entry also carried one label per hit spell, so it
could not have a second entry for the same hit.

## Considered options

1. A flat attack power fixture. It only adds (0 to 100000), so it cannot reach 0.
2. A stat aura set before the base measurements, kept through the trials, and a label suffix. Chosen.

## Decision

`script_hit` takes `stat_auras` (`[spell, stacks]`, set on the caster as the scenario's first steps) and `label_suffix`
(label `<spell> script_hit <hit> <suffix>`). Demoralizing Shout 1159613 (aura 99, -501) holds a Templar's 313 attack
power at 0 (Unit::GetTotalAttackPowerValue clamps below 0). The entry's `caster_auras` remove and set it again before
each trial, since a set on a present aura keeps its old duration.

## Consequences

- Divine Charge `no_power`: 84.4 per hit against the base-only model 83.85, and the trample 126.1 against 127.15,
  after ADR 0209.
- Entries without the fields regenerate byte-identical (1704 of 1704, one new scenario).
- Tests: `test_behaviours.ScriptHitStatAuraTests`.
