# Uncritical casts (`metric_delta` `uncritical_casts`, ADR 1288, provisional)

`uncritical_casts: {"casts": N, "min_uncritical": M}` (2 <= N <= 10, 1 <= M <= N) repeats the treatment cast block
(phase fixtures, power, cooldown reset, trigger cast, wait) N - 1 more times, each followed by its own reading
(`<after label> 2` .. `<after label> N`). Right after the before reading and after every treatment reading, the
caster's `spell_damage_count` of the trigger spell at the dummy is read twice, with `critical: true` and
`critical: false`.

The judge takes each treatment cast's difference of those cumulative counts: a cast with a critical damage event is
dropped, a cast with no non-critical hit is dropped, and every remaining cast is judged on its own reading against the
before reading with the entry's plain `metric_delta` rule (gain, ratio, bounds and tolerance as stated). Any remaining
cast that is not `ok` gives the verdict; fewer than M remaining casts leave the entry `unmeasured`. A missing reading
is `unmeasured`. The critical drop rests on the recorded damage event, never on a rate.

Refused outside the plain shape: the trigger cast at the dummy in both phases, the gate learned between them, no
`force_crit`, strike, trigger item, forced chance, game time or expiry read. Absent, the scenario and the verdict are
unchanged.

The entry states its residual: with a per-cast critical chance p, the entry is unmeasured with probability
P(more than N - M critical casts of N).

Felsworn: Doomsayer 520833 `control_no_crit` (Sargeron Smite 802060 refunds Felfury only on a critical strike; the
reference caster's natural spell crit chance reads 1.20828%, mentor D-116), N = 4, M = 2.
