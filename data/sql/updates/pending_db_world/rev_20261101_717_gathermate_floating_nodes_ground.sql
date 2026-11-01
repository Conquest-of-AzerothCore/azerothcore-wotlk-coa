-- Gathering nodes that float above their ground (#10577): rev_20261027_60_coa_gathermate_nodes.sql placed a Copper Vein
-- in Northshire Valley and 12 Duskwood Trees 15 to 227 yd above the terrain, where spawn_ground_gap finds nothing
-- but the terrain under them, so they show on the tracking minimap but cannot be reached or seen. Set them on the
-- terrain height read from the server .map files at their positions.
UPDATE `gameobject` SET `position_z` = 79.52
WHERE `guid` = 12006837 AND `id` = 1731 AND `map` = 0 AND `position_z` BETWEEN 109.11 AND 109.13;
UPDATE `gameobject` SET `position_z` = 41.32
WHERE `guid` = 12010688 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 75.80 AND 75.82;
UPDATE `gameobject` SET `position_z` = 122.08
WHERE `guid` = 12010850 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 180.38 AND 180.40;
UPDATE `gameobject` SET `position_z` = 31.32
WHERE `guid` = 12010892 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 65.21 AND 65.23;
UPDATE `gameobject` SET `position_z` = 78.95
WHERE `guid` = 12011177 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 106.16 AND 106.18;
UPDATE `gameobject` SET `position_z` = 162.98
WHERE `guid` = 12011180 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 381.75 AND 381.77;
UPDATE `gameobject` SET `position_z` = 36.37
WHERE `guid` = 12011318 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 70.59 AND 70.61;
UPDATE `gameobject` SET `position_z` = 47.18
WHERE `guid` = 12011326 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 73.97 AND 73.99;
UPDATE `gameobject` SET `position_z` = 129.25
WHERE `guid` = 12011328 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 315.93 AND 315.95;
UPDATE `gameobject` SET `position_z` = 139.00
WHERE `guid` = 12011329 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 319.38 AND 319.40;
UPDATE `gameobject` SET `position_z` = 46.93
WHERE `guid` = 12011334 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 62.37 AND 62.39;
UPDATE `gameobject` SET `position_z` = 97.40
WHERE `guid` = 12011341 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 324.01 AND 324.03;
UPDATE `gameobject` SET `position_z` = 30.18
WHERE `guid` = 12011344 AND `id` = 244618 AND `map` = 0 AND `position_z` BETWEEN 51.13 AND 51.15;
