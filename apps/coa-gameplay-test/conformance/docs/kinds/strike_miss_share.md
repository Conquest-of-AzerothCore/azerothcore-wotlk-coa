# Strike miss share (`behaviour_metric_delta`, `kind: "strike_miss_share"`, ADR 1123, provisional)

A claim that the caster cannot be hit ("chance to be hit by spells is reduced by 100%") read from real strikes. A
passive striker (creature 36, 3 yd, no `spell_hit_bonus`, so no attacker bonus offsets the claimed reduction) casts
`strike_spell` at the caster `strikes` times per burst, `strike_wait_ms` apart. `control_bursts` run first without
`trigger_spell`; then `treatment_bursts`, each starting with a real `trigger_spell` cast at the caster (base mana and a
cooldown reset first) and the strikes `trigger_wait_ms` later. Every burst lasts `burst_ms` from its start, so the
trigger's own auras end before the next cast. Before and after each burst the striker's SPELL_GO count of the strike
(sent) and its damage logs at the caster (landed; a miss logs none) are read, and `trigger_aura` is read on the caster
after the strikes. The caster holds 1,000,000 health, regeneration off.

Judge (label `<spell> behaviour_metric_delta <label_suffix>`, metric `spell_log_count`, event class): every burst
must send exactly `strikes`; the control must land at least `control_minimum_share` of its strikes and never hold the
aura; every treatment burst must hold it. Then `ok` when no treatment strike landed, `alert` when any did; otherwise
`unmeasured`. Size the treatment so the failure the claim rules out (the engine's least hit chance) shows a landed
strike with negligible residual probability, and state it in `observe_source`.

`refused` (`{"spell", "result", "attack_ms"}`, optional) adds two checks, `<label_suffix>_cast` (metric
`cast_failure`) and `<label_suffix>_attack` (metric `melee_attack_count`): before the bursts of each arm the caster
attempts `spell` at the striker and auto-attacks it for `attack_ms` (the treatment right after its own trigger cast).
The control must cast it (a SPELL_GO, no failure) and swing at least once, else `unmeasured`; the treatment, with the
aura read on, must be refused with `result` and send no SPELL_GO, and make no swing.

Witch Doctor: Slither 500947 `slither_spell_miss` (Light of the Naaru 41394, with the refusals) and
`slither_ranged_miss` (Cannon Shot 92522).
