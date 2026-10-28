-- #7708: Worldforged Withered Trollkin Shoulders cache (guid 6941348, entry 95855, Boulderfist cave,
-- Arathi Highlands) spawns inside rock; only the reporter's own position lands on the cave floor
-- polygon. Move it there.
UPDATE `gameobject` SET `position_x` = -1234.99, `position_y` = -1997.35, `position_z` = 37.22
    WHERE `guid` = 6941348 AND `id` = 95855;
