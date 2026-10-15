-- Razorfen Downs: Heroic/Mythic bosses that do not stand on Normal (placed ingame 30.09.2026), respawn 7 days.
DELETE FROM `creature` WHERE `guid` IN (9780116, 9780119, 9780122, 9780124);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9780116, 7354, 129, 0, 0, 4, 1, 1, 2457.98, 953.057, 35.287, 3.93569, 604800, 0.0, 0, 529512, 6156, 0, 0, 0, 0, '', NULL, 0, NULL),
(9780119, 7356, 129, 0, 0, 4, 1, 0, 2567.74, 936.537, 55.6075, 0.970099, 604800, 0.0, 0, 605100, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9780122, 7354, 129, 0, 0, 2, 1, 1, 2457.86, 952.837, 35.2814, 4.02057, 604800, 0.0, 0, 407317, 6156, 0, 0, 0, 0, '', NULL, 0, NULL),
(9780124, 7356, 129, 0, 0, 2, 1, 0, 2568.08, 936.498, 55.4776, 1.1099, 604800, 0.0, 0, 465462, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
