# Enemy spell power (`metric_delta` `enemy_spell_power`, ADR 1102)

`enemy_spell_power` is a positive spell power set as the `spell_power` fixture of the enemy player
(`enemy_player_race` is required), so a reduction of the enemy's spell power is read above the floor of 0. Absent,
the scenario is unchanged.

Named points: `check`, `fixtures`.

Witch Doctor: Shrinking Jinx 807833 `jinx_sp` (100 before, 15 after a real Jinx).
