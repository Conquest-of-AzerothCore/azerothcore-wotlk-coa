# Spread per crit (`behaviour_metric_delta`, `kind: "spread_per_crit"`, ADR 0721)

An aura copied to a nearby enemy on each critical hit. Each arm seeds `seed_spell` on the primary dummy (at the
`target_rank` cast distance), then casts `target_rank` at it with the `force_crit` rating fixture at 100000, so every
hit is a critical strike. `spell` is learned after the treatment seed, so the seed's own crit spreads nothing. Right
before and after the cast, the critical hits of `hit_spells` on the primary (`spell_damage_count` with `critical`, a
read that already exists) and the caster's `aura_spell` on `spares` spare dummies within `radius` yd beyond the primary
are read.

Judge: the control needs at least one crit (else unmeasured) and no copy (else alert); the treatment's new copies must
equal its new crits exactly (copies per crit 1.0), while at least one spare stays free after one copy per crit (a
saturated or crit-less treatment is unmeasured). Witch Hunter: Strafing Shot 705515 (Tormentor 800162, Witchbane
800165 and its hit 704342, six spares within 10 yd; claim 265.0).
