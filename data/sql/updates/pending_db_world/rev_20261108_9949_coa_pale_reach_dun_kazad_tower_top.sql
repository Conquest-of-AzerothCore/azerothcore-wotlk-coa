-- The tower top west of Dun Kazad as on the live realm (video V10AMkhYl6c 01:24:55-01:25:06): dwarves at the parapet
-- and nothing else. Ergrain Tattersail (164998) stands at the west corner, where her greeting has her feeling the
-- breeze; unnamed dwarves in dark armour stand at the south and north-west corners, filled by Dun Kazad Guards
-- (facings and the north-west guard set in game). Moer Stonefist (165622) and his roost props (gryphons, hay, water)
-- were added for the port and are removed; Gryphon Master Stonefeather serves Dun Kazad.
UPDATE `creature` SET `position_x` = -6720.4, `position_y` = -11.4, `position_z` = 581.333, `orientation` = 1.7111,
`Comment` = 'Ergrain Tattersail, Dun Kazad tower top, west corner (V10AMkhYl6c 01:24:59)'
WHERE `guid` = 9962265 AND `id` = 164998;

DELETE FROM `creature` WHERE `guid` IN (9993090, 9993091) AND `id` = 164403;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9993090, 164403, 0, 0, 0, 1, 1, 1, -6730.3, -16.6, 581.31, 2.0967, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dun Kazad Guard, tower top, south corner (V10AMkhYl6c 01:24:59)'),
(9993091, 164403, 0, 0, 0, 1, 1, 1, -6708.431, -12.353, 581.337, 1.1307, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dun Kazad Guard, tower top, north-west corner (placed in game)');

DELETE FROM `creature_addon` WHERE `guid` = 9999221;
DELETE FROM `creature` WHERE `guid` = 9999221 AND `id` = 165622;
DELETE FROM `gameobject_scale` WHERE `guid` IN (9999362, 9999389, 9999390, 9999392, 9999393, 9999395, 9999396);
DELETE FROM `gameobject` WHERE `guid` IN (9999362, 9999389, 9999390, 9999392, 9999393, 9999395, 9999396);
