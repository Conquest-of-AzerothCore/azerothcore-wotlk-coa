-- Teno Greybrook, the Armorer: this branch has his shop but never placed him; he stands where the user placed him.
DELETE FROM `creature` WHERE `guid` = 9965099;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9965099, 164130, 0, 0, 0, 1, 1, 0, -7631.67, 1209.64, 160.151, 4.5927, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Teno Greybrook (live capture spawn 633)');
