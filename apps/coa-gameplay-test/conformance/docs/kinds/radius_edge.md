# Radius edges (`behaviour_metric_delta`, `kind: "radius_edge"`, ADR 0592)

Three dummies stand on one line from the caster: the primary 3 yd out, one `margin_yd` (0.5) inside and one
`margin_yd` beyond the stated `radius` plus the dummy's combat reach `dummy_reach` (the engine's area test,
`WorldObject::IsWithinDist3d`, adds the target's object size). Each dummy's combat reach, height and distance to the
primary are read first; a layout that does not bracket the edge with the read values is unmeasured.

The control arm casts `cast_spell` at the primary `repeats` times (after `setup_casts` at the caster) before
`gate_spell` is learned; the treatment arm repeats the casts after it. `hit_spell` hits per dummy are read after each
arm (`spell_damage_count`, from `caster_entry` when given). Verdict: the treatment strikes the inside dummy and never
the outside one, the control strikes none; a treatment that never strikes the primary is unmeasured.

Fields: `gate_spell`, `cast_spell`, `hit_spell`, `radius`, `dummy_reach`, `reach_source`, optional `caster_entry`,
`learn`, `setup_casts`, `power` (set before each cast), `repeats` (3), `settle_ms` (1500), `margin_yd` (0.5).
