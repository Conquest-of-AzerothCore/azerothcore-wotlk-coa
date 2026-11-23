# Player spell power (`metric_delta` `player_spell_power`, ADR 0364)

`player_spell_power` sets the caster's harness spell-power fixture for the scenario (`players[0].spell_power`). With
`after_at_most` and `after_at_least` it judges one rolled amount inside its stated range at a set spell power (Harvest
Plague 583256: the first tick in [172, 210] at 0 and [3172, 3210] at 20000).

`{"amount": spell power, "hit_arm": true}` (ADR 0734) sets the same fixture and makes the entry a spell power arm
(D-57, ADR 0686): the scenario reads the caster's spell power of the trigger's first magic school right before the
judged reading, and the verdict records a positive read as `detail['spell_power']`, the spell power the hit ran at,
which `coverage.bonus_terms_unproven` requires of a hit when the spell's `spell_bonus_data` row has a spell power
coefficient. The entry's metric is the caster's `spell_damage_total` or `spell_heal_total` (refused otherwise). A
plain integer records nothing. Witch Hunter: Torchlight 503662 `torch_sp`.
