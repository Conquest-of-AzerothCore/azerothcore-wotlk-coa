# Extra strikes (`behaviour_metric_delta`, `kind: "extra_strikes"`, ADR 0693)

A talent that makes an off-hand auto attack strike `strikes` more times. The caster dual wields (the entry's weapon
set, or `off_hand_item` with a one-handed main hand) and auto-attacks the dummy for `control_swings` off-hand swing
intervals without the talent, then for `swings` with it learned. Each arm reads, at its start and end: the off-hand
and main-hand damaging swings (`melee_damage_count`), the casts of `proc_marker` (a spell the proc casts once, here
the Replenishment of the same tooltip) and, for every spell of `strike_spells`, its casts (`spell_cast_count`) and its
landed hits at the dummy (`spell_damage_count`).

The verdict (pooled over runs) is an alert when the control arm procs or strikes, unmeasured without a treatment
proc, and ok only when the landed strikes are exactly `strikes` per proc and every strike cast landed. The proc share
of the off-hand hits is reported with its Wilson 99% interval against `chance_pct`, not judged.

Brushin' Off The Dusk 681329 (2 strikes, 10%) and 681488 (3 strikes, 20%) count the casts of 681392 and 681489 (the
two ranks' Effect[0] triggers) against the casts of Replenishment 1257670.
