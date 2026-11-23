-- #12152: Herb node guid 200889 (pool 20068) was buried 3.43 yd below the ground (measured spawn_ground_gap); raise it to the floor
UPDATE `gameobject` SET `position_z` = 122.402 WHERE `guid` = 200889 AND `id` = 176586 AND `map` = 0
    AND `position_z` BETWEEN 118.8 AND 119.2;
