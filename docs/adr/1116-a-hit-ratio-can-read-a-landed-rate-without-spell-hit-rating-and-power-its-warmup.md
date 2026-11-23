# 1116. A hit ratio can read a landed rate without spell hit rating and power its warmup

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0195 (pooled hit_ratio rates), ADR 1048 (rate streams)

## Context

- Staff of the Coven 807905 "and your hit chance by $s2%" (clause 389, data only): aura 333 raises
  m_modSpellHitChance, and Unit::MagicSpellHitResult misses a same-level creature 4% of the time without it. No rate
  reads misses: `critical` and `proc` count events over damage hits. The reference character's spell hit rating of
  10000 removes every miss.
- Eye of Kimbul 503714 "Increases your damage dealt ... against this target by $s2%" (clause 76): five warmup casts put
  five Eyes on the dummy, but a percentage-cost warmup cast gets no power fixture, so the second arm cannot afford them.

## Decision

- `hit_ratio` `rate: "landed"`: the event read is the observed spell's `spell_damage_count` at the target and the count
  read its `spell_go_count` (every cast packet, a miss included), so the rate is the percent of casts that land. It needs
  the damage metric, the caster's own casts of the observed spell, and no swings or `cast_spell`.
- `hit_ratio` `fixture` accepts `spell_hit_rating` (the player fixture rating, as `spell_power`).
- `hit_ratio` `warmup_power` (needs `warmup`): the power is set to that value before every warmup cast.
- Witch Doctor entries `807905 behaviour_hit_ratio hit_landed` (+4 points, 16 parts, 8 streams) and
  `503714 behaviour_hit_ratio eye_damage` (1.05).

## Consequences

- New values and fields only; absent, every scenario is unchanged. Classes 19 (with and without `--stack`) and 23
  generate byte-identical.
- Seeded tests in `test_landed_rate_and_ally_strikes.py`.
