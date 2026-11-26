# Target order (`metric_delta` `target_order`, ADR 1276)

`target_order` is `{"spell": hit spell, "events": hits per target and cast, "centre": "dummy"|"caster", "casts": N}`
on an entry with a plain `area_dummies` list and the dummy as its target. After the after reading, the treatment phase
(from the expiry wait to the after reading) is repeated until it has been cast N times. A base read before the
treatment phase and a read after each cast give, per target (the dummy and each area dummy): the damage of `spell`
without critical, resisted or blocked hits (`spell_damage_total`), the count of those hits and the count of all hits
(`spell_damage_count`), and every unit's `position_x/y/z`. Labels are `<spell> <metric> after order <cast> <unit>
<read>`.

Judge (after the plain before/after judge, which it keeps): per cast, the targets are ranked by their measured
distance from the centre (the dummy, or the caster); a cast with two distances within 0.01 yd is void. A target hit
other than `events` times in a cast alerts. The mean plain damage per rank, over the casts where the target took only
plain hits, must fall strictly from the nearest to the farthest; a rank with no such cast, or every cast void, is
`unmeasured`. A missing read alerts. It states no amount: a direction-only claim (mentor D-100, D-101).

Named point: `verdict(verdict, run, value)` (`metric_delta_options.option_verdict`); `fixtures` adds the casts
and reads.

Felsworn: Hellfire Carver 707444 `target_order` (Fel Fireball 801312 on 9 targets, centre the primary, 16 casts, claim
185.1) and Carve 800206 `target_order` (end slash 803715 on 9 targets in front, centre the caster, 8 casts, claim
204.0).
