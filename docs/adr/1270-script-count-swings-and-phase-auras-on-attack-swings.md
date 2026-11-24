# 1270. A swung script count proves consumption per landed attack; attack swings take phase auras

- Status: proposed
- Date: 2026-11-24
- Related: [ADR 1258](1258-an-opted-in-script-count-read-proves-a-stated-count-driven-by-real-casts.md) (the
  `script_count` opt-in), [ADR 0170](0170-auras-set-around-behaviour-casts.md) (`phase_auras`),
  `ratio_to_metric` (its option doc, `docs/metric_delta_options/ratio_to_metric.md`).
- Decided by: mentor D-95 (four conditions), controller go of 2026-11-24 for both parts.

## Context

Felsworn Annihilation 803904 ("Lasts for $n attacks") and Pit Lord's Strength 802076 and 802110 ("now affects $s1
additional attack") were read only as the count stored right after the cast (data, ADR 1258): the attacks that
consume it were not read. The `script_count` plain layout refuses `attack_swings`, and an `attack_swings` entry
never casts its trigger.

Grommash's Folly 805236 ("you now heal equal to $807426s1% of all damage dealt by critical strikes with auto attacks")
applies only while Inner Demon 804216 is on the caster, and `attack_swings` refused `phase_auras`, so the heal share
of the swings could not be measured with its condition held.

## Options

- Count the swings that ran while the aura was held (harness C++ beyond reading; G-39) — not taken.
- Infer consumption from the caster's 5% health cost per attack — measures one clause through another; not taken.
- A `script_count` sub-key `swings`: swing after each real cast for a window shorter than the count, then judge the
  count plus the landed attacks since the cast against the stated count, with per-reading consumption conditions.
- For 805236: let `attack_swings` take `phase_auras`, set before each phase's attack.

## Decision

`script_count.swings` (noun `attack` only, opt-in): after each real trigger cast the scenario reads the count and the
caster's `melee_damage_count`, attacks the dummy for `swings` reference intervals, stops, and reads
`melee_damage_count` after the reading. A counted reading is the count plus the landed attacks since the cast, and is
missing unless at least one attack landed, the count is strictly below the cast count, and the sum equals the cast
count (mentor D-95 condition 1). The window must stay below every counted reading, so the aura cannot end inside
it. `melee_damage_count` without a hand sums both hands, so the bound counts every melee hand the scenario equips
(slots 15 and 16): each hand lands at most `window // speed + 1` attacks, and the generator refuses the entry when
the sum reaches the least reading of a cast arm. The fixture keeps the class's real weapons, a dual-wield included,
because the aura is consumed by any landed attack, whichever hand swings. Felsworn dual-wields 2300 ms weapons, so
its consumed entries swing 1 interval (4 landed attacks at most, below 5). Missed or avoided swings and the aura's
end at the last count stay untested (D-95 conditions 2 and 3); the end is reachable within the 12000 ms duration
(up to 12 landed attacks with both hands), but the window stops before it.

`attack_swings` takes `phase_auras`, set at the start of each phase and followed by a `wait_ms` wait before the
attack, so what the aura's scripts apply is in place for the first swing; `after_auras` stay refused.

## Consequences

- Entries without `swings` or `phase_auras` generate byte-identical scenarios and models; finished classes 15, 19,
  19 `--stack`, 23 and 27 regenerate byte-identical.
- No change to judges, tolerances, evidence classes or closing keys: the swung reading feeds the existing
  `aura_script_count` judgement; 805236 uses the existing `ratio_to_metric` increments.
- The consumption parts count on condition 1 with the note "expiry edge untested".
