-- #11955: Worldforged object guid 8000520 floated 6.58 yd above the ground (measured spawn_ground_gap); lower it to the floor
UPDATE `gameobject` SET `position_z` = 53.349 WHERE `guid` = 8000520 AND `id` = 244626 AND `map` = 0
    AND `position_z` BETWEEN 59.8 AND 60.1;
