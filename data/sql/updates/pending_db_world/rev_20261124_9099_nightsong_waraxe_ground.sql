-- Worldforged Nightsong Waraxe (object 515425, guid 6941991), Ashenvale (#9099): the realm-map pass moved the pickup
-- 7.5 yd uphill from first-pass row 6900434 (2224.557, -3116.910) and kept that row's z 122.261, so it sat 1.31 yd
-- under the slope. New z: the server's ground height at the spawn XY (spawn_ground_gap -1.306).
UPDATE `gameobject` SET `position_z` = 123.567
WHERE `guid` = 6941991 AND `id` = 515425 AND `map` = 1 AND `position_z` BETWEEN 122.256 AND 122.266;
