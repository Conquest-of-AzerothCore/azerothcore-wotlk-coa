# Cooldown tick cut (`behaviour_metric_delta`, `kind: "cooldown_tick_cut"`, ADR 1197)

A periodic cut of a remaining cooldown ("the remaining cooldown of Horusath Blast is reduced by 10% every 1 sec"),
read on the cooldown itself. `spell` (the periodic aura) and `cooled_spell` are learned with `phase_aura` set on the
caster, `cooled_spell` is cast at the dummy, and its `cooldown_ms` is read `reads` times (3 to 80, default 61),
`read_step_ms` apart (at least 100, below the amplitude, default 100), each read with `game_time_ms`. The reads must
span enough amplitudes of `spell` effect `amplitude_effect` (DBC
`EffectAmplitude`) that `2 * read_step_ms / (ticks - 1)` stays below 5% of the amplitude, `ticks` being the span over
the amplitude rounded down; another layout is refused.

An interval shorter than the amplitude holds at most one tick. A tick shows as a drop more than 50 ms beyond the
game time elapsed, `r1 - D - r2`. For such an interval the per-tick cut `p` satisfies
`r2 = (1 - p)(r1 - a) - (D - a)` for an unknown tick offset `a` in `[0, D]`, so `1 - (r2 + D) / r1` and
`1 - r2 / (r1 - D)` bracket `p` with no tick epoch. Every tick's bracket must lie inside the G-19 band of
`expected_pct`, and the ticks found must number the span of the reads over the amplitude, rounded down or up. The
count alone does not prove the period (a 900 or 1100 ms period can give an allowed count over a short span), so the
period has its own bracket: tick `j` falls in its read interval `[s_j, e_j]`, and the period lies between
`(s_j - e_i) / (j - i)` and `(e_j - s_i) / (j - i)` for every pair of ticks. That bracket must lie inside the
amplitude +- 5%, so a period 10% off on either side never passes. One cut bracket or the period bracket wholly
outside its band, an empty period bracket (unevenly spaced ticks), or another count, alerts. A control entry with the
other phase aura expects 0
and no tick at all. An interval as long as the amplitude, or a cooldown that runs out during the reads, is
unmeasured.

The derived metric `cooldown_tick_cut_pct` is an event (behaviour): it is the server's tick handler observed acting
on the cooldown over time, not a stored value read back.

Sun Cleric: Day Cycles 300361, Horusath Blast 500154 in Sunrise 500477 and Rapture 806477 in Sunset 500511,
cut 10% per 1000 ms tick (301176 Effect[1] BasePoints 9 + DieSides 1).
