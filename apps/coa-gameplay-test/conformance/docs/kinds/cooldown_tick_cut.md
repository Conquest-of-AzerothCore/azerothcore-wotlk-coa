# Cooldown tick cut (`behaviour_metric_delta`, `kind: "cooldown_tick_cut"`, ADR 1027)

A periodic cut of a remaining cooldown ("the remaining cooldown of Horusath Blast is reduced by 10% every 1 sec"),
read on the cooldown itself. `spell` (the periodic aura) and `cooled_spell` are learned with `phase_aura` set on the
caster, `cooled_spell` is cast at the dummy, and its `cooldown_ms` is read `reads` times (3 to 40, default 13),
`read_step_ms` apart (at least 100, below the amplitude, default 250), each read with `game_time_ms`; the reads span
at least two amplitudes of `spell` effect `amplitude_effect` (DBC `EffectAmplitude`).

An interval shorter than the amplitude holds at most one tick. A tick shows as a drop more than 50 ms beyond the
game time elapsed, `r1 - D - r2`. For such an interval the per-tick cut `p` satisfies
`r2 = (1 - p)(r1 - a) - (D - a)` for an unknown tick offset `a` in `[0, D]`, so `1 - (r2 + D) / r1` and
`1 - r2 / (r1 - D)` bracket `p` with no tick epoch. Every tick's bracket must lie inside the G-19 band of
`expected_pct`, and the ticks found must number the span of the reads over the amplitude, rounded down or up, which
proves the period too; one bracket wholly outside, or another count, alerts. A control entry with the other phase aura
expects 0 and no tick at all. An interval as long as the amplitude, or a cooldown that runs out during the reads, is
unmeasured.

The derived metric `cooldown_tick_cut_pct` is an event (behaviour): it is the server's tick handler observed acting
on the cooldown over time, not a stored value read back.

Sun Cleric: Day Cycles 300361, Horusath Blast 500154 in Sunrise 500477 and Rapture 806477 in Sunset 500511,
cut 10% per 1000 ms tick (301176 Effect[1] BasePoints 9 + DieSides 1).
