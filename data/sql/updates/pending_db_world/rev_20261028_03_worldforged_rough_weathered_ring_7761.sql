-- #7761: Worldforged Rough Weathered Ring (guid 6940979, entry 1345116, Arathi Highlands) has no
-- walkable navmesh polygon at its spawn XY (blocked, inside a map doodad). Move it to the reporter's
-- own position, which lands on open ground.
UPDATE `gameobject` SET `position_x` = -831.49, `position_y` = -3277.81, `position_z` = 79.44
    WHERE `guid` = 6940979 AND `id` = 1345116;
