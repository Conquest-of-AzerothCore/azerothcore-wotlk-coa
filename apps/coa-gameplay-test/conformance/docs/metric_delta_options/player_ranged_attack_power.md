# Player ranged attack power (`metric_delta` `player_ranged_attack_power`, ADR 0863)

`player_ranged_attack_power` is a positive ranged attack power the caster holds for the scenario: the harness player
fixture `players[0].ranged_attack_power` (a flat `UNIT_MOD_ATTACK_POWER_RANGED` total value, the same fixture family as
`player_attack_power`). It lets a hit judge the `$RAP` term of a tooltip apart from the `$AP` and `$SP` terms. It adds
no check. Absent, the scenario is unchanged.

Witch Hunter: Feast of Talons 500056 `crows_rap` (the crows 500564, `$RAP*0.1` per tick).
