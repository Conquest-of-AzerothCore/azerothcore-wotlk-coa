-- GatherMate Peacebloom 12002331 (Elwynn) was imported 18 yd above the terrain, in a tree canopy where it could not be reached (#11257). Set it on the terrain the server measures at its x/y (71.61).
UPDATE `gameobject` SET `position_z` = 71.61 WHERE `guid` = 12002331 AND `id` = 1618 AND `map` = 0 AND `position_z` BETWEEN 89.62 AND 89.64;
