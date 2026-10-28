-- Worldforged Treasure Seeking Lodestone (#8691, duplicates #6061 and #8421): the realm-map pass
-- moved the Ancient Elven Chest (gameobject guid 6942358) 23 yd to its map marker in Tanaris but
-- kept the height it had at the old spot, leaving it 4.01 yd under the sloped ground at the new
-- XY (confirmed with the gameplay harness's own terrain probe: spawn_ground_gap -4.0128). Raise it
-- onto the ground; XY, orientation and rotation are unchanged.

UPDATE `gameobject`
SET `position_z` = 18.348
WHERE `guid` = 6942358 AND `id` = 515800 AND `map` = 1 AND `position_z` BETWEEN 14.3 AND 14.4;
