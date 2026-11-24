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

Options for a trigger with a cooldown and a percent cost (ADR 1192, provisional), all optional and absent by default:

- `residual_target` and `min_detectable`: the residual sizing of proc entries (`procs.residual_sizing`, ADR 0781); the
  judge takes Wilson at that confidence, the minimum trials are the larger of the band's and the residual's, and the
  verdict states the residual probabilities.
- `reset_between_attempts`: a harness `reset_cooldown` of the trigger before every cast. That fixture sends one
  `SMSG_CLEAR_COOLDOWN` of the trigger itself, so when `reset_spell` is the trigger the control must read exactly one
  packet per fixture reset (else alert, "fixture packets not 1:1") and the treatment fixture resets are subtracted.
- `base_mana_per_attempt`: the caster's mana is set to the class file's `base_mana` before every cast
  (`hits.base_mana_steps`); it lifts the refusal of a percent-cost trigger and is refused without such a cost.
- `trial_casts`: the trials are the trigger's completed casts (`spell_cast_count`), for a handler that rolls on the
  cast, hit or not.

Sun Cleric: Piety 300367 on Horusath Blast 572801 (11 parts) and Rapture 806477 (19 parts), 20%, with all four,
`residual_target` 0.001 and `min_detectable` 4 (twice the 2-point band).
