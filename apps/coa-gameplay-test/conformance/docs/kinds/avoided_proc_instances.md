# Avoided-proc instances (`behaviour_metric_delta`, `kind: "avoided_proc_instances"`, ADR 1260, provisional)

A proc of avoided swings that grants an aura spent over a stated number of instances ("your next 10 instances of
damage with Twin Slice ... and generate 1 Felfury"), obtained by the real route (mentor D-67): never set by
`set_aura`.

Steps: the `proc_avoided` strikers (`striker_entry`, `strikers`, `striker_auras`, `swing_ms`) engage the caster. The
control arm casts `cast_spell` at the first striker `casts` times, `cast_gap_ms` apart; before each cast the caster's
health is set to full, its dodge and parry to 0, `stack_aura` to 0 stacks and `power` to `power_value`. After each cast:
the `stack_aura` stacks, `proc_aura` presence, `aura_script_value` of `proc_aura` (a readback, reported only), game time
and the `spell_damage_count` of each `hit_spells` on the striker. Then `spell` is learned, `proc_windows` windows of
dodge 100 obtain the proc, `proc_aura` presence, apply count, remaining duration and game time are read, the same casts
run, and the apply count is read again.

Judge: own gain g = the control stacks per cast (must be constant; `proc_aura` never held). Extra per treatment cast =
stacks - g. `gain_per_instance` (label `... gain_per_instance`) = the extra over the hits of the casts after which
`proc_aura` is still held, `ok` at exactly 1. `instances` (label `... instances`) = the summed extra over that gain,
`ok` at exactly `instances` (stated in `quote` as "`instances` instances") with `proc_aura` held after a cast exactly
while the counted instances are below it. `unmeasured` (void) on a missing read, a refused cast, no proc at the start,
a new application during the casts, `proc_aura` gone by its duration, a varying control gain, or no held cast.

Felsworn: Vengeance Is Mine 804822 (807163, Twin Slice 801901 with hits 808303 and 808304, Felfury 800058).
