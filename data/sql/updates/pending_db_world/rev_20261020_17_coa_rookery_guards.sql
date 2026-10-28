-- The Rookery (#7489): the Pristine Black Dragon Egg was guarded only by whelps and condors;
-- the orcs the quest text names were never spawned at the rookery.
--
-- The camp at -9715 -2897 is a Blackrock dragon-tender site (Tirig 254978 is a
-- "Blackrock Dragon Tender"), and the local Blackrock camp lies ~180 yards east. Add four
-- Blackrock guards around the egg on the terrain heights, matching the level 18 quest.

DELETE FROM `creature` WHERE `guid` BETWEEN 9001380 AND 9001383;
INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
     `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`,
     `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`,
     `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9001380, 440,  0, 0, 0, 1, 1, 0, -9709.0, -2892.0, 52.2, 3.83, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Rookery guard - Blackrock Grunt (#7489)'),
(9001381, 440,  0, 0, 0, 1, 1, 0, -9708.0, -2902.0, 52.6, 2.52, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Rookery guard - Blackrock Grunt (#7489)'),
(9001382, 4064, 0, 0, 0, 1, 1, 0, -9720.0, -2891.0, 53.9, 5.41, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Rookery guard - Blackrock Scout (#7489)'),
(9001383, 4065, 0, 0, 0, 1, 1, 0, -9720.0, -2904.0, 55.1, 0.95, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Rookery guard - Blackrock Sentry (#7489)');
