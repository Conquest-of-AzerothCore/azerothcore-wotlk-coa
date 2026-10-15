-- Scarlet Monastery and Scholomance fixes after ingame check (02.10.2026)

-- Scarlet Monastery Graveyard: Azshir, Ironspine and Scorn at the Ascension positions placed ingame on Mythic,
-- now on every difficulty
UPDATE `creature` SET `spawnMask` = 7 WHERE `guid` IN (9780157, 9780158, 9780159);

-- Scorn (14693) had trash stats on Heroic/Mythic: same as Azshir now (level 63, rare elite, boss damage and health)
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `rank` = 2, `DamageModifier` = 4.21 WHERE `entry` = 114693;
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `rank` = 2, `DamageModifier` = 5.47 WHERE `entry` = 214693;
DELETE FROM `coa_dungeon_health` WHERE `map_id` = 189 AND `creature_entry` = 14693;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(189, 1, 14693, 406232, 'assumption', 'as Azshir the Sleepless (02.10.2026); Scorn'),
(189, 2, 14693, 528101, 'assumption', 'as Azshir the Sleepless (02.10.2026); Scorn');

-- Herod's Door (Armory) stays open
UPDATE `gameobject` SET `state` = 0 WHERE `guid` = 32250 AND `id` = 101854;

-- Scholomance: Jandice Barov's illusions at about 10% of her health
DELETE FROM `coa_dungeon_health` WHERE `map_id` = 289 AND `creature_entry` = 11439;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(289, 1, 11439, 32596, 'assumption', '10% of Jandice Barov (02.10.2026); Illusion of Jandice Barov'),
(289, 2, 11439, 42375, 'assumption', '10% of Jandice Barov (02.10.2026); Illusion of Jandice Barov');
-- Darkmaster Gandling's Rise! (2100398) summons Ascension's Risen Student (80066), which did not exist here

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(80066, 180066, 280066, 0, 0, 0, 'Risen Student', NULL, NULL, 0, 58, 58, 0, 21, 0, 1.0, 1.14286, 1.0, 1.0, 20.0, 0, 0, 1.0, 2000, 2000, 1.0, 1.0, 1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0, 1, 0, 0, '', 0),
(180066, 0, 0, 0, 0, 0, 'Risen Student', NULL, NULL, 0, 60, 60, 0, 21, 0, 1.0, 1.14286, 1.0, 1.0, 20.0, 0, 0, 1.0, 2000, 2000, 1.0, 1.0, 1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0, 1, 0, 0, '', 0),
(280066, 0, 0, 0, 0, 0, 'Risen Student', NULL, NULL, 0, 62, 62, 0, 21, 0, 1.0, 1.14286, 1.0, 1.0, 20.0, 0, 0, 1.3, 2000, 2000, 1.0, 1.0, 1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0, 1, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (80066, 180066, 280066);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(80066, 0, 24996, 1.0, 1.0, 0),
(80066, 1, 24997, 1.0, 1.0, 0),
(80066, 2, 24999, 1.0, 1.0, 0),
(180066, 0, 24996, 1.0, 1.0, 0),
(180066, 1, 24997, 1.0, 1.0, 0),
(180066, 2, 24999, 1.0, 1.0, 0),
(280066, 0, 24996, 1.0, 1.0, 0),
(280066, 1, 24997, 1.0, 1.0, 0),
(280066, 2, 24999, 1.0, 1.0, 0);

DELETE FROM `coa_dungeon_health` WHERE `map_id` = 289 AND `creature_entry` = 80066;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(289, 1, 80066, 6000, 'assumption', 'ghoul from Rise! (02.10.2026); Risen Student'),
(289, 2, 80066, 8000, 'assumption', 'ghoul from Rise! (02.10.2026); Risen Student');
