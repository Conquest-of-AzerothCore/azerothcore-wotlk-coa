-- #11963: Worldforged crossbow guid 6941013 floated 1.06 yd above the ground (measured spawn_ground_gap); lower it to the floor
UPDATE `gameobject` SET `position_z` = 77.403 WHERE `guid` = 6941013 AND `id` = 90498 AND `map` = 0
    AND `position_z` BETWEEN 78.3 AND 78.6;
