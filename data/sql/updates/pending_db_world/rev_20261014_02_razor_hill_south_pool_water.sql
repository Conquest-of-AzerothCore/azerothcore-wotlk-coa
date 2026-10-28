-- Collect Water (267033) fills Dirgran's Pitcher only within 6 yards of a 162949 trigger; the south pool had none.
DELETE FROM `creature` WHERE `guid` = 9012307;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9012307, 162949, 1, 0, 0, 1, 1, 0, 215.92, -4754.89, 5.44, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: the pool south of town by the bridge (water 7.40); invisible, Collect Water reaches 6 yd');
