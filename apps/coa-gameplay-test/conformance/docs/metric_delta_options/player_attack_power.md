# Player attack power (`metric_delta` `player_attack_power`, ADR 0734)

`player_attack_power` is a positive attack power the caster holds for the scenario: the harness player fixture
`players[0].attack_power` (a flat `UNIT_MOD_ATTACK_POWER` total value). Paired with a `player_spell_power` entry of
the same spell, the attack power and spell power terms of one hit are judged apart. It adds no check. Absent, the
scenario is unchanged.

Witch Hunter: Torchlight 503662 `torch_ap` (one forced critical hit at +20000 attack power).
