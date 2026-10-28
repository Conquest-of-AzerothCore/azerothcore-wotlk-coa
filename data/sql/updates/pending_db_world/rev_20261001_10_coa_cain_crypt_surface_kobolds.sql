-- Three Kobold Desecrators 161751 above the Cain Family Crypt: CoA footage shows kobolds at the tomb on the way
-- down to Restless Family Members; until now they were only inside. They stand around the back of the tomb
-- (playtest: bunched at the entrance): the roof outline (centre 1791.1, 1953.4, radius 15.1, entrance to the
-- north-west) gives an arc behind it, and each stands on open terrain 2.5-4 yd off its walls (surface.standable),
-- about 12 yd from the next, facing the tomb (INFERRED).
DELETE FROM `creature` WHERE `guid` IN (9010901, 9010902, 9010903);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9010901, 161751, 0, 0, 0, 1, 1, 0, 1774.42, 1958.91, 154.725, 5.96, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator behind the tomb, west side'),
(9010902, 161751, 0, 0, 0, 1, 1, 0, 1782.03, 1936.57, 156.21, 1.08, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator behind the tomb, south side'),
(9010903, 161751, 0, 0, 0, 1, 1, 0, 1804.89, 1942.45, 156.413, 2.47, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator behind the tomb, east side');
