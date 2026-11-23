# Enemy casts before (`metric_delta` `enemy_casts_before`, ADR 1113, provisional)

`enemy_casts_before` is a non-empty list of distinct spell ids. Once, at the start of the before phase and before
any trigger cast (named point `phase_steps`), the enemy player learns each spell and casts it at itself, 500 ms
apart. It needs `enemy_player_race`. Use it for a state the enemy must hold when the trigger is cast and that lasts
through the treatment phase, such as a shapeshift form (`enemy_casts` cast after the trigger). Absent, the scenario
is unchanged.

Witch Doctor: Hir'eek's Jinx 803325 `jinx_player_lasts` (an enemy Tauren Druid in Cat Form 768, a Beast for the
Beast-only Jinx, holds the fear for the 8 sec stated against players).
