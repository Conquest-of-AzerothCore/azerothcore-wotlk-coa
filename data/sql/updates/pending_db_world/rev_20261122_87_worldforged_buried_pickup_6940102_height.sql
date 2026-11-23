-- #11907: Worldforged pickup guid 6940102 sat 0.67 yd below the ground (measured spawn_ground_gap); raise it to the floor
UPDATE `gameobject` SET `position_z` = 31.218 WHERE `guid` = 6940102 AND `id` = 254234 AND `map` = 0
    AND `position_z` BETWEEN 30.4 AND 30.7;
