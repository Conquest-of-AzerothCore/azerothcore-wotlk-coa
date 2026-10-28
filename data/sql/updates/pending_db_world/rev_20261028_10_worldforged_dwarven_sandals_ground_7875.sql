-- #7875: Worldforged Dwarven Sandals pickup (guid 6940404, entry 517336, Loch Modan) floats 1.08 yd
-- above the stock terrain at its own spawn XY, which the reporter stands on next to it. Set it to that
-- terrain height; XY is unchanged.
UPDATE `gameobject` SET `position_z` = 309.018 WHERE `guid` = 6940404 AND `id` = 517336;
