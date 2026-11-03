-- The GatherMate import (#9555) placed Briarthorn 12001309 in Duskwood 24.7 yd above the terrain, in a tree canopy
-- where it cannot be seen or clicked (#10812). Set it on the terrain height read from the server .map files.
UPDATE `gameobject` SET `position_z` = 31.68
WHERE `guid` = 12001309 AND `id` = 1621 AND `map` = 0 AND `position_z` BETWEEN 56.33 AND 56.35;
