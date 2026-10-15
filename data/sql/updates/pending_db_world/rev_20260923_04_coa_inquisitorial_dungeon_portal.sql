-- Conquest of Azeroth's portal between the Secret Inquisitorial Dungeon under Old Northshire Village and the
-- Vaults of the Inquisition (map 936). The client carries both trigger boxes, but the world has never had the
-- rows that make them work, so walking to the dead end of the corridor below the tomb hall does nothing.
--
-- WHERE EACH VALUE COMES FROM
--   triggers  AreaTrigger.dbc 8002 (the tombs, map 0) and 8003 (inside the Vaults), copied as they are:
--     box_x, box_y, box_z and box_o become length, width, height and orientation.
--   arrival points  on the server floor 9-11 yd past the other side's box, facing away from it: inside, on the
--     landing below the entry stair, facing into the Vaults; in the tombs, on the landing of the stair back up
--     to the tomb hall.
--   instance  map 936 is a dungeon in Map.dbc; its parent is map 0, so 8003 is its way out.
--   portal objects  CoA's own type-31 portals for map 936 from the client object cache: normal 2300565,
--     heroic 2300566 and mythic 2300567. Each side has one of each at one point, as stock dungeons pair
--     theirs, on the floor at the face of the trigger box the player walks toward.
--   graveyard  WorldSafeLocs.dbc 6074 Shadewell Spring Graveyard, the CoA graveyard on the ridge above the tombs,
--     was never imported. Neither the tombs (zone 10197) nor the Vaults (zone 10218) had a linked graveyard, so a
--     ghost released there, and Resurrect in Closest Town, sent Alliance players to Westfall and Horde players to
--     the Crossroads. Both zones now use Shadewell Spring.
--   Dungeon Finder  LFGDungeons.dbc 401, 1401 and 2401 enter the random dungeon pools once 8002 leads to map
--     936. The Vaults are still empty, so the Dungeon Finder leaves them out; walking in is not affected.
--   difficulties  inside, each portal spawns only in its own difficulty (spawnMask 1, 2, 4), as stock dungeons do.
--
-- Gameobject guid block 7912000-7912099.

DELETE FROM `areatrigger` WHERE `entry` IN (8002, 8003);
INSERT INTO `areatrigger` (`entry`, `map`, `x`, `y`, `z`, `radius`, `length`, `width`, `height`, `orientation`)
VALUES
(8002, 0, -8628.39, -491.709, 44.7732, 0, 17, 4, 10, 0),
(8003, 936, -6658.54, -5553.9, 183.4, 0, 17, 4, 10, 0);

DELETE FROM `areatrigger_teleport` WHERE `ID` IN (8002, 8003);
INSERT INTO `areatrigger_teleport` (`ID`, `Name`, `target_map`, `target_position_x`, `target_position_y`,
    `target_position_z`, `target_orientation`)
VALUES
(8002, 'Secret Inquisitorial Dungeon - Vaults of the Inquisition', 936, -6658.54, -5565, 175.05, 4.712389),
(8003, 'Vaults of the Inquisition - Secret Inquisitorial Dungeon', 0, -8628.39, -479, 43.56, 1.5707964);

DELETE FROM `instance_template` WHERE `map` = 936;
INSERT INTO `instance_template` (`map`, `parent`, `script`, `allowMount`)
VALUES
(936, 0, '', 0);

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`,
    `Data0`, `Data1`, `AIName`, `ScriptName`)
VALUES
(2300565, 31, 8196, 'Doodad_InstanceNewPortal_Purple01', '', '', 1.75, 936, 0, '', ''),
(2300566, 31, 8197, 'Doodad_InstanceNewPortal_Purple_Skull01', '', '', 1.75, 936, 1, '', ''),
(2300567, 31, 9040, 'Doodad_InstancePortal_Green_5Man_Mythic01', '', '', 1.5, 936, 2, '', '')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`),
    `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `AIName` = VALUES(`AIName`),
    `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `gameobject` WHERE `guid` IN (7912000, 7912001, 7912002, 7912003, 7912004, 7912005);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
    `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
    `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7912000, 2300565, 0, 0, 0, 1, 1, -8628.39, -489.8, 40.111, 1.5707964, 0, 0, 0.7071068, 0.7071068, 300, 100, 1, '',
    'CoA Vaults portal (normal): trigger 8002 at the end of the tombs, on the floor at the box face'),
(7912001, 2300566, 0, 0, 0, 1, 1, -8628.39, -489.8, 40.111, 1.5707964, 0, 0, 0.7071068, 0.7071068, 300, 100, 1, '',
    'CoA Vaults portal (heroic): trigger 8002 at the end of the tombs, on the floor at the box face'),
(7912002, 2300567, 0, 0, 0, 1, 1, -8628.39, -489.8, 40.111, 1.5707964, 0, 0, 0.7071068, 0.7071068, 300, 100, 1, '',
    'CoA Vaults portal (mythic): trigger 8002 at the end of the tombs, on the floor at the box face'),
(7912003, 2300565, 936, 0, 0, 1, 1, -6658.54, -5555.8, 178.549, 4.712389, 0, 0, 0.7071068, -0.7071068, 300, 100, 1,
    '', 'CoA Vaults exit portal (normal): trigger 8003 on the entry-stair landing, on the floor at the box face'),
(7912004, 2300566, 936, 0, 0, 2, 1, -6658.54, -5555.8, 178.549, 4.712389, 0, 0, 0.7071068, -0.7071068, 300, 100, 1,
    '', 'CoA Vaults exit portal (heroic): trigger 8003 on the entry-stair landing, on the floor at the box face'),
(7912005, 2300567, 936, 0, 0, 4, 1, -6658.54, -5555.8, 178.549, 4.712389, 0, 0, 0.7071068, -0.7071068, 300, 100, 1,
    '', 'CoA Vaults exit portal (mythic): trigger 8003 on the entry-stair landing, on the floor at the box face');

DELETE FROM `disables` WHERE `sourceType` = 8 AND `entry` = 936;
INSERT INTO `disables` (`sourceType`, `entry`, `flags`, `params_0`, `params_1`, `comment`)
VALUES
(8, 936, 7, '', '', 'Vaults of the Inquisition - no Dungeon Finder until the instance is populated');

DELETE FROM `game_graveyard` WHERE `ID` = 6074;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`)
VALUES
(6074, 0, -8594.75, -615.457, 144.698, 'Elwynn Forest, Shadewell Spring');

DELETE FROM `graveyard_zone` WHERE `GhostZone` IN (10197, 10218);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(6074, 10197, 0, 'Secret Inquisitorial Dungeon - Elwynn Forest, Shadewell Spring'),
(6074, 10218, 0, 'Vaults of the Inquisition - Elwynn Forest, Shadewell Spring');
