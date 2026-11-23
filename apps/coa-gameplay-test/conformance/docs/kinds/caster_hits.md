# Caster hits (`behaviour_metric_delta`, `kind: "caster_hits"`, ADR 1253)

Hits of one spell per caster per cast on one dummy. One or two players of the class (`casters`; the second is
`caster2`) stand at `trial_position`, which is also the scenario's `location`, with the dummy `dummy_distance` yd
ahead. Each of `trials` trials teleports every caster back to that spot (each must read within 0.5 yd) and reads the
dummy's position, sets `caster_auras`, reads every caster's own `hit_spell` hits on the dummy (`spell_damage_count`),
gives each caster `cast_power` and casts `cast_spell` at the dummy, or at itself with `cast_target` "self" (the second
caster `gap_ms` after the first), waits `settle_ms` and reads again. Each read pair is judged by the `metric_delta`
judge: the trial must add exactly `hits_per_cast` to each caster's count, from 0 before the first cast.

Fel Torpedo 500610 (Felsworn ADR 0013): `torpedo_once` and `torpedo_once_far` (one caster, 2 and 9 yd) and
`torpedo_two_casters` (two casters, 100 ms apart), one 500761 hit per caster per cast.
