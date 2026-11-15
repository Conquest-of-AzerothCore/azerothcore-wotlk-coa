-- Dire Maul West: Lord Hel'nurath and his two Dread Guards stand at the summoning circle before Immol'thar on Ascension
-- (db.exil.es spawns 56803, 84241, 84242); this fork had none of them (#11380).
DELETE FROM `creature` WHERE `guid` IN (9429001, 9429002, 9429003);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9429001,14506,429,2557,2557,7,1,0,-2.88,705.3,-24.4,4.71239,86400,0,0,0,0,0,0,0,0,'',0,0,'Lord Hel''nurath'),
(9429002,14483,429,2557,2557,7,1,0,2.86,696.61,-24.4,4.71239,86400,0,0,0,0,0,0,0,0,'',0,0,'Dread Guard'),
(9429003,14483,429,2557,2557,7,1,0,-11.04,701.4,-24.4,4.71239,86400,0,0,0,0,0,0,0,0,'',0,0,'Dread Guard');
