# Avoided-swing internal cooldown (`behaviour_metric_delta`, `kind: "avoided_icd"`, ADR 1212, provisional)

A timer on a proc of avoided swings ("Can only occur once per sec.") that no cast can space. `strikers` aggressive,
stationary strikers (`striker_entry`, `striker_auras` set from themselves) engage the caster as in the avoided proc
trigger (`proc_avoided`, misses counted); before every `swing_ms` window the caster's health is set to full and its dodge
and parry to 50% and 50%, so every swing is dodged, parried or missed. `control_windows` windows run before `spell` is
learned and must give no `hit_spell` hit; `windows` windows run with it. Reads: the `hit_spell` damage events of the
caster on any striker (`spell_damage_count`), the shortest and median interval between them
(`event_interval_min_ms`, `event_interval_median_ms`, stream `spell_damage`), the avoided swings at the learn and at
the end, and the attacks taken. After the windows and the drain the caster is relocated 20 yd along x (`relocate`) and
waits 200 ms, so the stationary strikers cannot swing while the outcome reads are taken one per world tick; it then
reads its distance to every striker and the attacks taken once before and once after the dodged, parried and missed
reads.

Judge: `ok` when the shortest interval lies in `[timer - 5%, timer + 5%]`, a band that excludes a timer 10% shorter or
longer; `alert` outside it or on a hit before the learn. `unmeasured` (void) on a missing read, a refused cast in
`cast_failures`, a caster within 17 yd (the relocation less the strikers' 3 yd spawn distance) of any striker after the
relocation, a total of attacks taken that differs between its first and last read, attacks taken other than the dodged,
parried and missed swings, fewer than 20 intervals, or fewer than
10 avoided swings per hit. The contract states the residual: with at least 10 avoided swings per hit and independent
uniform swing phases (an assumption, not measured), a wrong verdict needs every one of at least 20 intervals to wait
more than 50 ms, probability at most 2^-20 per run. The generator refuses windows too short for 20 intervals of a
timer 10% longer.

Sun Cleric: Protector of the Flame 560492 (Fire damage 560493 to the attacker, `Chance(player, 560492, 1000)`).
