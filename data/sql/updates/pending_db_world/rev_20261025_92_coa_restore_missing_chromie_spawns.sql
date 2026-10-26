-- Restore missing capital spawns without moving or duplicating an existing Chromie on either map.
-- Coordinates follow the original Chromie migration and the Stormwind height correction.
INSERT IGNORE INTO `creature`
(`id`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`,
 `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`)
SELECT 178081, 0, 1, 1, 0, -8820.67, 625.782, 94.344, 3.78035, 300, 0, 0, 0, 0, 0
FROM `creature_template` WHERE `entry` = 178081
AND NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 178081 AND `map` = 0);

INSERT IGNORE INTO `creature`
(`id`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`,
 `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`)
SELECT 178081, 1, 1, 1, 0, 1581.6, -4418.4, 8.2, 3.38266, 300, 0, 0, 0, 0, 0
FROM `creature_template` WHERE `entry` = 178081
AND NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 178081 AND `map` = 1);
