# Player spell power (`metric_delta` `player_spell_power`, ADR 0364)

`player_spell_power` sets the caster's harness spell-power fixture for the scenario (`players[0].spell_power`). With
`after_at_most` and `after_at_least` it judges one rolled amount inside its stated range at a set spell power (Harvest
Plague 583256: the first tick in [172, 210] at 0 and [3172, 3210] at 20000).
