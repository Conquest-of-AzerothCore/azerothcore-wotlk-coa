# Spawn fuse (`behaviour_metric_delta`, `kind: "spawn_fuse"`, ADR 0602)

A proc that summons a creature which casts a spell a fixed time after it appears ("explode after N sec"). An
encounter timeline (`encounter_start` on the dummy) records every spawn and cast on the map. A forcing fixture raises
`talent`'s roll by 1000% for the scenario and is removed and read gone at the end. Control: `control_casts` casts of
`trigger_spell` at the dummy before `talent` is learned; the timeline must hold no spawn of `entry`. Treatment:
`casts` casts with it learned, then `settle_ms`; the first `fuse_spell` cast by a creature `entry`
(`timeline_first_ms`, `event` `cast`, `source_entry`) minus the first spawn of `entry` is judged against
`expected_ms` in the G-19 band. No spawn is unmeasured; a spawn without its fuse cast, a control spawn or a kept
mutant alerts.

Necromancer: Muck Summoner 806086, Rotlings 50133 casting 500585 after $807640t2 = 5 sec (claim 279.0).
