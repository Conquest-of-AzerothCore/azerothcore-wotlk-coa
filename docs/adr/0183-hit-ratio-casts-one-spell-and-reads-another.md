# 0183. Hit ratio casts one spell and reads another

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0125 (hit ratios) and ADR 0142 (off-hand hit ratios)

## Context

Righteous Tempest 805409, "Consumes your Oaths, dealing additional damage for each consumed." The level 60 rank
807274 applies an aura that hits with 570205 at the cast and every second for 5 s. Its Oath bonus is baked into the
aura when it is applied: the script sums the held Oaths' Effect[2] amounts into the aura's script value, and every
570205 hit is multiplied by 1 + value / 100. The `oath_consumption_removal` entry reads that script value, a
readback. A `hit_ratio` entry reads the hits of the spell it casts, so it could not read 570205 after a cast of
807274.

## Options

1. Set the Tempest aura with `set_aura`. Its hits would come without the cast, and the cast path is what the clause
   describes.
2. A new kind for periodic hit ratios. It repeats the arms, reads and judge of `hit_ratio`.
3. Let `hit_ratio` cast `cast_spell` in each trial, wait `cast_wait_ms`, and read the hits of `observe_spell`.

## Decision

Option 3. The caster learns and casts `cast_spell` (armed for it); the reads, the arms and the judge are unchanged.
`cast_spell` must differ from `observe_spell`, `cast_wait_ms` must not be negative, and a wait without a
`cast_spell` or a cast with swings is refused. Entries without the fields regenerate byte-identical.

## Consequences

- Righteous Tempest reads +59.4% and +59.6% with two Oaths against the stated 1.60 (the script's sum is additive;
  a product would be 1.69), and +29.5% to +29.8% with each Oath alone.
- A ratio with a stat aura as its treatment still needs an expected value computed from the control's mean. For the
  spell power term of 570205 the reference mean of the weapon part is not derived (a first estimate, 1.279, read
  1.254), so that claim is left to its route agent.
