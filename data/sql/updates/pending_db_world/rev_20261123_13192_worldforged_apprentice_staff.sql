-- #13192: Worldforged Apprentice Staff had two spawns 19 yd apart in the Barrens; the second (6970022) is the nearest realm sighting.
DELETE FROM `gameobject` WHERE `guid` = 6970021 AND `id` = 9900023 AND `map` = 1;
