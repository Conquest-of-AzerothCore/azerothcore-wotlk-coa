# Cooldown reset rate (`behaviour_metric_delta`, `kind: "cooldown_reset_rate"`, ADR 0603)

A talent's chance to reset another spell's cooldown on each hit of a cost-free trigger. `reset_spell` and
`trigger_spell` are learned; `trigger_spell` is cast at the dummy `control_casts` times before `talent` is learned and
`casts` times after, `cast_wait_ms` apart. A reset is a `SMSG_CLEAR_COOLDOWN` (0x1DE) whose first field is
`reset_spell`, counted by `server_packets` with `row`; trials are the trigger's damaging hits on the dummy
(`spell_damage_count`). A control reset alerts; the treatment rate is judged as a proc rate (Wilson 99% interval, the
G-20 band of `chance_pct`). An entry with fewer `casts` than the band needs, or a trigger with a cost, is refused.

Necromancer: Unholy Runes 561353, Blight 500237 resetting Corpse Explosion 533236 at 5% (claim 137.0).
