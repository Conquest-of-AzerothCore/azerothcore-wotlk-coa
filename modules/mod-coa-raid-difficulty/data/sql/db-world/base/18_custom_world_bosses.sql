-- Ascension's own world bosses in their boss maps: Setis (880), The Will of
-- Soggoth (883), Korrim Snowgrave (889). Entries are Ascension's, as the
-- combat log shows them. The maps and vmaps come from the client's
-- patch-WB1/patch-WB2 and have to be extracted into the server's data folder.

-- Two levels per boss, both measured (one kill each in the 24.08.2026 log):
-- the lower on difficulties 0 and 1, the higher on 2 and 3. damage_pct is the
-- log's hits over the base value of the same spell.
CREATE TABLE IF NOT EXISTS `coa_world_boss_level` (
  `entry` INT UNSIGNED NOT NULL,
  `difficulty` TINYINT UNSIGNED NOT NULL,
  `health` INT UNSIGNED NOT NULL,
  `damage_pct` FLOAT NOT NULL DEFAULT 100,
  `note` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`entry`, `difficulty`)
);

DELETE FROM `coa_world_boss_level` WHERE `entry` IN (64600, 64605, 64627, 454004);
INSERT INTO `coa_world_boss_level` (`entry`, `difficulty`, `health`, `damage_pct`, `note`) VALUES
(64600, 0, 10504882, 75, 'kill 22:28, 15 players'),
(64600, 2, 19509068, 93, 'kill 22:41, 15 players'),
(64627, 0, 24642076, 168, 'kill 23:24, 22 players'),
(64627, 2, 31379032, 217, 'kill 23:36, 24 players'),
(64605, 0, 14611055, 81, 'kill 00:28, 21 players'),
(64605, 2, 21351728, 99, 'kill 00:44, 21 players'),
(454004, 0, 402192, 81, 'Psychophage, full health taken by 23 of them'),
(454004, 2, 587412, 99, 'Psychophage, full health taken by 38 of them');

-- Templates: Azuregos' as the base (level 63 boss, his immunities and weapon).
DELETE FROM `creature_template` WHERE `entry` IN (64600, 64605, 64627, 454004);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`,
  `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`,
  `lootid`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`,
  `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
SELECT n.entry, n.name, '', 63, 63, 0, 14, 0, t.speed_walk, t.speed_run, t.detection_range, n.rnk, 0, n.dmg, t.BaseAttackTime,
  t.RangeAttackTime, t.BaseVariance, t.RangeVariance, 1, 0, 0, 0, 0, n.type, t.type_flags, 0, '', 0, 1, 1, 1, t.ArmorModifier, 1,
  0, 0, 1, n.immune, n.extra, n.script, 12340
FROM `creature_template` t
JOIN (SELECT 64600 AS entry, 'Setis' AS name, 3 AS rnk, 7 AS type, 20.45 AS dmg, -294 AS immune, 1 AS extra, 'boss_setis_coa' AS script
      UNION ALL SELECT 64627, 'Korrim Snowgrave', 3, 5, 20.45, -294, 1, 'boss_snowgrave_coa'
      UNION ALL SELECT 64605, 'The Will of Soggoth', 3, 10, 20.45, -294, 1, 'boss_soggoth_coa'
      UNION ALL SELECT 454004, 'Psychophage', 1, 10, 4, 0, 0, 'npc_psychophage_coa') n
WHERE t.entry = 6109;

-- Setis: the model of the Silithus rare he is named after. Korrim: the client's
-- korrim.m2 at the boss scale. Soggoth and the Psychophages: no model in any
-- data here; Ulduar's Faceless Horror and Guardian of Yogg-Saron stand in.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (64600, 64605, 64627, 454004);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(64600, 0, 5965, 3, 1, 12340),
(64627, 0, 142079, 1, 1, 12340),
(64605, 0, 28844, 2, 1, 12340),
(454004, 0, 28465, 1, 1, 12340);

-- Korrim's display has no model info in this database; Lord Kazzak's (another
-- large model) is copied so the server knows his reach.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 142079;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`)
SELECT 142079, `BoundingRadius`, `CombatReach`, 2, 0, 12340 FROM `creature_model_info` WHERE `DisplayID` = 12449;

DELETE FROM `instance_template` WHERE `map` IN (880, 883, 889);
INSERT INTO `instance_template` (`map`, `parent`, `script`, `allowMount`) VALUES
(880, 1, '', 0),
(883, 0, '', 0),
(889, 571, '', 0);

-- Spawns. Setis stands where the Silithus rare stands (map 880 is a copy of
-- that corner, height from its terrain). Soggoth and Snowgrave: their arenas
-- are built from models, not terrain, so the only known floor is the map's
-- graveyard (WorldSafeLocs 6083, 6089); they wait there until someone places
-- them in the arena.
DELETE FROM `creature` WHERE `id` IN (64600, 64605, 64627);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`) VALUES
(9780101, 64600, 880, 0, 0, 15, 1, 0, -7970.9, 1507.22, 2.61, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780102, 64605, 883, 0, 0, 15, 1, 0, 4410.5, 269.3, 78.0, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780103, 64627, 889, 0, 0, 15, 1, 0, 4741.1, -4935.0, 695.8, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0);

-- GM teleports to each graveyard.
DELETE FROM `game_tele` WHERE `name` IN ('SetisBossMap', 'SoggothBossMap', 'SnowgraveBossMap');
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
SELECT COALESCE(MAX(`id`), 0) + 1, -8093.0, 1663.6, 12.9, 0, 880, 'SetisBossMap' FROM `game_tele`;
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
SELECT MAX(`id`) + 1, 4410.5, 269.3, 78.0, 0, 883, 'SoggothBossMap' FROM `game_tele`;
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
SELECT MAX(`id`) + 1, 4741.1, -4935.0, 695.8, 0, 889, 'SnowgraveBossMap' FROM `game_tele`;
