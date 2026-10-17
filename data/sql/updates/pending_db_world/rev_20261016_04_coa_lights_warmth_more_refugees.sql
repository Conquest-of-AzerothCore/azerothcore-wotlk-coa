-- Two more Exhausted Refugees by the watchtower's east Cozy Fire, one sitting and one lying, as in the user's live screenshot.
DELETE FROM `creature` WHERE `guid` IN (9965158, 9965159);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(9965158, 164069, 0, 0, 0, 1, 1, 0, -6993.6, 497.4, 350.4, 2.4, 300, 0, 0, 'Exhausted Refugee, sitting by the east fire (Light''s Warmth)'),
(9965159, 164068, 0, 0, 0, 1, 1, 0, -6997.8, 497.1, 350.4, 0.6, 300, 0, 0, 'Exhausted Refugee, lying by the east fire (Light''s Warmth)');
DELETE FROM `creature_addon` WHERE `guid` IN (9965158, 9965159);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9965158, 0, 0, 1, 1, 0, 0, ''),
(9965159, 0, 0, 3, 1, 0, 0, '');
