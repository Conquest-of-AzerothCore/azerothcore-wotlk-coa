-- Worldforged Red Metal Pauldrons (#8740): the Eastern Plaguelands pickup (gameobject guid
-- 6940946, entry 1345112) stood 0.75 yd under the stock terrain at its spawn XY (confirmed with
-- the gameplay harness's own ground probe: spawn_ground_gap -0.753082, terrain 129.376). Raise it
-- onto the ground; XY and orientation are unchanged.

UPDATE `gameobject`
SET `position_z` = 129.38
WHERE `guid` = 6940946 AND `id` = 1345112 AND `map` = 0 AND `position_z` BETWEEN 128.5 AND 128.7;
