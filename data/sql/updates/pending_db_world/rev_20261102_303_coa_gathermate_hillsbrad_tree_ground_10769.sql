-- The GatherMate import (#9555) placed Hillsbrad Tree 12014480 8.8 yd above the terrain, so the node floats
-- (#10769). Set it on the terrain height read from the server .map files.
UPDATE `gameobject` SET `position_z` = 56.35
WHERE `guid` = 12014480 AND `id` = 244621 AND `map` = 0 AND `position_z` BETWEEN 65.11 AND 65.13;
