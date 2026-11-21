# 0213. Judge a cast's stat gain on its target against the caster's stats

- Status: accepted
- Date: 2026-11-12

## Context

Improved Benediction 705287, claim 196: "Benediction now grants your target armor based on your Agility and Stamina".
Libram of Fervor 805423, claims 411 and 412: "granting you spell power equal to $s2% of your Agility and attack power
equal to $s1% of your Intellect". The stored reads were `aura_amount` and `effect_value` readbacks. No kind read the
stat a real cast changes on its target and compared the change with the caster's own stats; `metric_delta` judges two
absolute readings, and `cast_stat_ratio` compares an aura amount with one stat.

## Options

1. A `metric_delta` per stat value, with the expected gain written in. It holds only at the reference stats and cannot
   show that the gain follows the stat.
2. A new kind, `stat_gain`, judged on the gain with arms that change the source stats.

## Decision

Option 2, under the `behaviour_metric_delta` check name (model kind `stat_gain`). The entry names `cast_spell`,
`cast_target` (`caster` or `ally`, the ally grouped as in ADR 0212, `target_health_pct` before each cast), the target
`metric` and `fields`, `terms` (a `coefficient` times the sum of its `reads`, stat metrics read on the caster, as in
the `taken_hit` absorb terms), `clear_auras` (removed from the target before each cast) and `arms`. Each arm learns its
spells, sets its auras on the caster, reads the terms, reads the target metric, casts, waits `wait_ms` (default 500)
and reads it again. An arm with `gain` is judged exactly against it; an arm without is judged against the formula on
the stats it read, inside the truncation window floor(x) to ceil(x) (the stat ruling: deterministic, judged to the
rounding). At least two arms, at least one judged by the formula.

## Consequences

- Improved Benediction on build 861e0e1e6bee (counted 20261112-015203 / -015316): the grouped ally's armor gains 0
  without the talent, 211 with it (Agility 132 + Stamina 79), and the sum of the stats read with Agility 58451 and with
  Stamina 48101 set.
- Libram of Fervor: Holy spell power +39 (30% of 132, window 39-40) and +48 with Agility 162; attack power +9 (30% of
  32) and +24 with Intellect 80.
- Seeded tests: a gain off the stats in any arm alerts; a percent gain passes inside its truncation window only; an
  entry with no formula arm is refused. Existing scenarios regenerate byte-identical.

## Addendum (review fixes, 2026-11-12)

The formula arm is judged at floor(x) only, the integer the engine's truncation gives, not floor(x) to ceil(x): every
read was floor or exact (39, 48, 9, 24, 211, 241, 274).
