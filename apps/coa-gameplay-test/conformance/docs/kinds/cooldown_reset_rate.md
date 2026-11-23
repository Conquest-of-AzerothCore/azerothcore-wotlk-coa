# Cooldown reset rate (`behaviour_metric_delta`, `kind: "cooldown_reset_rate"`, ADR 0603)

A talent's chance to reset another spell's cooldown on each hit of a cost-free trigger. `reset_spell` and
`trigger_spell` are learned; `trigger_spell` is cast at the dummy `control_casts` times before `talent` is learned and
`casts` times after, `cast_wait_ms` apart. A reset is a `SMSG_CLEAR_COOLDOWN` (0x1DE) whose first field is
`reset_spell`, counted by `server_packets` with `row`; trials are the trigger's damaging hits on the dummy
(`spell_damage_count`). A control reset alerts; the treatment rate is judged as a proc rate (Wilson 99% interval, the
G-20 band of `chance_pct`). An entry with fewer `casts` than the band needs, or a trigger with a cost, is refused.

Necromancer: Unholy Runes 561353, Blight 500237 resetting Corpse Explosion 533236 at 5% (claim 137.0).

An optional `cast_power` sets the trigger's power to that value before every cast, so a trigger with a flat cost can
repeat (ADR 0703); it must cover the cost and is refused for a percent or per-level cost. Without it a costly
trigger is refused as before. Each cast then takes three steps, so the 10000-step limit caps the casts near 3300.

An optional `attempt_auras` (`[{"spell", "stacks", "source"}]`) sets each caster aura right before every trigger cast,
after the power refill (ADR 0719): a trigger whose CasterAuraSpell is consumed by its own cast (Desecrate and
Desperation 803166) repeats. Each cast then takes one more step per aura, inside the same step limit. Witch Hunter:
Wicked Intent 504645 (Desecrate 681211 at 400 raw Rage with 803166 before every cast, resetting Noctis Blade at 15%;
claim 68.0), pooled over several cases (`pool_cases`) because one case cannot hold its trials.

Pooled cases (ADR 0720): with `parts` N (the behaviour generator's identical cases, `... part 1` to `part N`), each
case casts `casts` times and the judge sums the control and treatment hits and resets over every part; `casts` x N
must reach the band's trials. A control reset in any part alerts, and a missing part leaves the claim unmeasured
(`compare` runs the pooled judge only when every part ran). The contract states the pooled count and its residual
failure probability (at most 1%, the Wilson 99% interval). The case limit is the accelerated one hour, so a 1.5 s
global cooldown trigger holds about 2200 casts per case.

An optional `dummy_distance` (0 to 100 yd) places the dummy at that distance, for a ranged trigger with a minimum range
(Witch Hunter: Expulsion of Evil 139778, Shadowblast 680269 at 17.5 yd; claim 8.0, 2 pooled parts).
