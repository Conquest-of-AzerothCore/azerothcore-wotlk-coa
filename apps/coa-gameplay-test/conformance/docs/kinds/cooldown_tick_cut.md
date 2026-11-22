# Cooldown tick cut (`behaviour_metric_delta`, `kind: "cooldown_tick_cut"`, ADR 1027)

A periodic cut of a remaining cooldown ("the remaining cooldown of Horusath Blast is reduced by 10% every 1 sec"),
read on the cooldown itself. `spell` (the periodic aura) and `cooled_spell` are learned with `phase_aura` set on the
caster, `cooled_spell` is cast at the dummy, and its `cooldown_ms` is read `reads` times (3 to 20, default 4), one
amplitude of `spell` effect `amplitude_effect` (DBC `EffectAmplitude`) apart, each read with `game_time_ms`.

An interval of exactly one amplitude holds exactly one tick wherever the tick falls, so the per-tick cut `p` of a
remaining cooldown satisfies `r2 = (1 - p)(r1 - a) - (D - a)` for an unknown tick offset `a` in `[0, D]`. Its two
ends, `1 - (r2 + D) / r1` and `1 - r2 / (r1 - D)`, bracket `p` with no tick epoch. Every interval's bracket must lie
inside the G-19 band of `expected_pct`; one wholly outside alerts. An interval whose game time differs from the
amplitude, or a cooldown that runs out during the reads, is unmeasured. A control entry with the other phase aura
expects 0 (the cooldown falls with time only, `r2 = r1 - D`).

The derived metric `cooldown_tick_cut_pct` is an event (behaviour): it is the server's tick handler observed acting
on the cooldown over time, not a stored value read back.

Sun Cleric: Day Cycles 300361, Horusath Blast 500154 in Sunrise 500477 and Rapture 806477 in Sunset 500511,
cut 10% per 1000 ms tick (301176 Effect[1] BasePoints 9 + DieSides 1).
