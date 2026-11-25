-- The Will of Soggoth shows himself only once his three heralds are dead: Corla, Herald of Twilight (64606),
-- High Priestess Azil (64607) and Drahga Shadowburner (64608), with the models of the WDB caches.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `detection_range`, `rank`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`,
  `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `HealthModifier`, `ManaModifier`, `ArmorModifier`,
  `ScriptName`, `VerifiedBuild`) VALUES
(64606, 'Corla, Herald of Twilight', '', 63, 63, 14, 0, 2, 1.71429, 40, 1, 4, 2000, 2000, 2, 0, 7, 0, '', 1, 1,
  1.3, 'npc_soggoth_herald_coa', 12340),
(64607, 'High Priestess Azil', '', 63, 63, 14, 0, 2, 1.71429, 40, 1, 4, 2000, 2000, 2, 0, 7, 0, '', 1, 1, 1.3,
  'npc_soggoth_herald_coa', 12340),
(64608, 'Drahga Shadowburner', '', 63, 63, 14, 0, 2, 1.71429, 40, 1, 4, 2000, 2000, 2, 0, 7, 0, '', 1, 1, 1.3,
  'npc_soggoth_herald_coa', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `faction` = VALUES(`faction`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`),
  `DamageModifier` = VALUES(`DamageModifier`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (64606, 64607, 64608);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(64606, 0, 31546, 1, 1, 12340),
(64607, 0, 454000, 1, 1, 12340),
(64608, 0, 31792, 1, 1, 12340);

-- Health per player in his map, like his own; their damage follows his level.
DELETE FROM `coa_world_boss_level` WHERE `entry` IN (64606, 64607, 64608);
INSERT INTO `coa_world_boss_level` (`entry`, `difficulty`, `health`, `damage_pct`, `note`) VALUES
(64606, 0, 100000, 81, 'per player; Soggoth herald, designed'),
(64607, 0, 100000, 81, 'per player; Soggoth herald, designed'),
(64608, 0, 100000, 81, 'per player; Soggoth herald, designed');

-- They stand in a triangle around him on the cavern floor (spots taken in game), facing him; dead, they stay dead
-- until a wipe or an instance reset brings them back.
DELETE FROM `creature` WHERE `guid` IN (9781600, 9781601, 9781602, 9781603);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9781600, 64606, 883, 10238, 10238, 15, 1, 4512.10, 284.54, 74.54, 5.07, 604800, 0, 0),
(9781601, 64607, 883, 10238, 10238, 15, 1, 4544.60, 246.56, 74.54, 2.77, 604800, 0, 0),
(9781602, 64608, 883, 10238, 10238, 15, 1, 4514.09, 233.26, 74.54, 1.16, 604800, 0, 0);

-- His hologram above the shrine at the entrance of his map too.
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9781603, 978077, 883, 10238, 10238, 15, 1, 4405.5, 264.3, 83.0, 0, 300, 0, 0);

-- The models the client gives these creatures their own scale (Creature.dbc): no extra scale on top.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 5965, `DisplayScale` = 1 WHERE `CreatureID` = 64600;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 92610, `DisplayScale` = 1 WHERE `CreatureID` = 454004;

-- Psychophages are level 61.
UPDATE `creature_template` SET `minlevel` = 61, `maxlevel` = 61 WHERE `entry` = 454004;
