-- Razorfen Downs Heroic/Mythic boss tuning after ingame check (30.09.2026)
-- Tuten'kash and Plaguemaw had no Heroic/Mythic templates and stayed level 37 there

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(107355, 0, 0, 0, 0, 0, 'Tuten''kash', NULL, NULL, 0, 63, 63, 0, 152, 0, 1.0, 1.14286, 1.0, 1.0, 20.0, 1, 0, 3.9, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 6, 0, 7355, 0, 0, 0, 0, 0, 0, '', 1, 1.0, 16.0, 1.0, 1.0, 2.0, 0, 0, 1, -93, 0, '', 12340),
(107356, 0, 0, 0, 0, 0, 'Plaguemaw the Rotting', NULL, NULL, 0, 63, 63, 0, 152, 0, 1.62, 1.14286, 1.0, 1.0, 20.0, 1, 0, 3.91, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 7, 0, 7356, 0, 0, 0, 0, 575, 756, '', 0, 1.0, 16.0, 1.0, 1.0, 2.0, 0, 0, 1, -93, 0, '', 12340),
(207355, 0, 0, 0, 0, 0, 'Tuten''kash', NULL, NULL, 0, 63, 63, 0, 152, 0, 1.0, 1.14286, 1.0, 1.0, 20.0, 1, 0, 5.1, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 6, 0, 7355, 0, 0, 0, 0, 0, 0, '', 1, 1.0, 16.0, 1.0, 1.0, 2.0, 0, 0, 1, -93, 0, '', 12340),
(207356, 0, 0, 0, 0, 0, 'Plaguemaw the Rotting', NULL, NULL, 0, 63, 63, 0, 152, 0, 1.62, 1.14286, 1.0, 1.0, 20.0, 1, 0, 5.09, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 7, 0, 7356, 0, 0, 0, 0, 575, 756, '', 0, 1.0, 16.0, 1.0, 1.0, 2.0, 0, 0, 1, -93, 0, '', 12340)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (107355, 107356, 207355, 207356);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(107355, 0, 7845, 1.0, 1.0, 51831),
(107356, 0, 6124, 1.0, 1.0, 51831),
(207355, 0, 7845, 1.0, 1.0, 51831),
(207356, 0, 6124, 1.0, 1.0, 51831);
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (107355, 107356, 207355, 207356);
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) VALUES
(107355, 0, 12252, 12340),
(107355, 1, 3391, 12340),
(107355, 2, 12255, 12340),
(107355, 3, 12251, 12340),
(107356, 0, 12946, 12340),
(107356, 1, 11441, 12340),
(207355, 0, 12252, 12340),
(207355, 1, 3391, 12340),
(207355, 2, 12255, 12340),
(207355, 3, 12251, 12340),
(207356, 0, 12946, 12340),
(207356, 1, 11441, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` IN (107355, 107356, 207355, 207356);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(107355, 0, 0, 0, 1, 0, 0, '12254 8876'),
(207355, 0, 0, 0, 1, 0, 0, '12254 8876');

UPDATE `creature_template` SET `difficulty_entry_1` = `entry` + 100000, `difficulty_entry_2` = `entry` + 200000 WHERE `entry` IN (7355, 7356);

-- Melee damage (ingame feedback 30.09.2026): Heroic auto hits ~400-600, Fierce Blow (200 % weapon damage) ~800-1200,
-- Mythic = Heroic * 1.3. Raw avg swing at level 63 = (damage_base * 1.25 + AP / 14) * attack time * DamageModifier:
-- warrior 127.7, paladin 118.8, mage 93.2 per 2 s swing (Glutton 178.7 per 2.8 s swing, target ~650 on Heroic).
UPDATE `creature_template` SET `DamageModifier` = 5.4 WHERE `entry` IN (107354, 107357); -- Ragglesnout, Mordresh (mage)
UPDATE `creature_template` SET `DamageModifier` = 7.0 WHERE `entry` IN (207354, 207357);
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` IN (107355, 107356); -- Tuten'kash, Plaguemaw
UPDATE `creature_template` SET `DamageModifier` = 5.1 WHERE `entry` IN (207355, 207356);
UPDATE `creature_template` SET `DamageModifier` = 4.2 WHERE `entry` = 107358;            -- Amnennar (paladin)
UPDATE `creature_template` SET `DamageModifier` = 5.5 WHERE `entry` = 207358;
UPDATE `creature_template` SET `DamageModifier` = 3.6 WHERE `entry` = 108567;            -- Glutton
UPDATE `creature_template` SET `DamageModifier` = 4.7 WHERE `entry` = 208567;

-- Ragglesnout: the vanilla rare spawn stays Normal only, Heroic/Mythic use the Ascension spawns 9780116/9780122
UPDATE `creature` SET `spawnMask` = 1 WHERE `guid` = 247108 AND `id` = 7354;

-- Steal Warmth: damage split among everyone in the 5 yard circle (targets set in SpellInfoCorrections)
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (2100710, 2100711);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (2100710, 0x00000008), (2100711, 0x00000008);
