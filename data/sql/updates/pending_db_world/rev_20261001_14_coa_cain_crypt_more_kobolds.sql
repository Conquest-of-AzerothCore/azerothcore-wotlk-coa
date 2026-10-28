-- Three more Kobold Desecrators 161751 inside the Cain Family Crypt, in rooms that stood empty: the first room
-- inside the entrance (z 141.4, at a position and facing taken in game with .gps, playtest), the west chamber,
-- and the small bone chamber north of the lower hall (on its floor at 125.15; a collision slab 6.5 yd above it
-- is not floor). The chamber kobolds keep 6+ yd from the relatives' remains, so the passages stay clear
-- (surface.standable on Deathknell_Cainfamilycrypt.wmo), and face the crypt's centre (INFERRED).
DELETE FROM `creature` WHERE `guid` IN (9010904, 9010905, 9010906);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9010904, 161751, 0, 0, 0, 1, 1, 0, 1768.4216, 1981.9938, 141.4457, 5.6337, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; entry room, west end'),
(9010905, 161751, 0, 0, 0, 1, 1, 0, 1766, 1953, 132.544, 0.17, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; west chamber'),
(9010906, 161751, 0, 0, 0, 1, 1, 0, 1787.6, 1982, 125.154, 4.37, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; bone chamber north of the lower hall');
