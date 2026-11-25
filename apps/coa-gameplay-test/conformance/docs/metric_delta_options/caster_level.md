# Caster level (`metric_delta` `caster_level`, ADR 1291)

`caster_level` is an integer level from `1` to `60`, strictly below the class file's level. It sets
`scenario['players'][0]['level']` so the harness spawns and normalizes the caster at that level (`Player::GiveLevel` in
`Normalize`, before any scenario step runs) and learns the passive gate spell at that level. Unlike
`phase_caster_level`, it does not change level mid-scenario (which does not recompute already-applied passive auras).

Under ruling G-32, the option refuses any entry whose `quote` does not contain the word `level`, any level above 60 or
at/above the class level, and any entry that also sets `phase_caster_level` or `shifted_control`.

The option reads the caster's `level` metric right before the `before` and `after` measurements and voids the trial
(`unmeasured`) if either read is missing or differs from `caster_level`. Absent, the scenario is unchanged.

Named points: `check`, `fixtures`, `model`, `verdict`.

Cultist: Voidwarding 560002 `res_*_l50` (resistances at level 50: `+14` across all 6 magic schools, paired with `+19`
at level 60).
