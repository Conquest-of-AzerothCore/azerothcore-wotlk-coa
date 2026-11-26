-- Onyxian Whelp in four difficulties, and Onyxia's flex health cut by 30%.
--
-- The whelp's only variant was the stock level-80 25-player template 36566, picked on Heroic and Ascended, while
-- Mythic fell back to Normal. The whelp now follows Onyxia's base + 100000 / 200000 / 300000 convention: copies of
-- 11262 with its model, movement, resistance, spell and addon rows.
--
-- Health follows the raid difficulty ratio of coa_boss_flex (Normal 0.75 : Heroic 1 : Mythic 1.505 :
-- Ascended 2.195), anchored on the whelp's Normal health. CoA.CreatureScaling.Raid.Health (2.2) applies only on
-- Normal, so the variants carry it in their HealthModifier:
--   Heroic   2.2 / 0.75         = 2.933333
--   Mythic   2.2 * 1.505 / 0.75 = 4.414667
--   Ascended 2.2 * 2.195 / 0.75 = 6.438667
--
-- Level 63 is the live realm's value for Onyxia and 11262 (2026-11-25); no tracked update sets it, so it is pinned
-- here before the copies are taken.

UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63 WHERE `entry` IN (10184, 110184, 210184, 310184, 11262);

DROP TEMPORARY TABLE IF EXISTS `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template` WHERE `entry` = 11262;
UPDATE `coa_whelp_copy` SET `entry` = 111262, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
INSERT INTO `creature_template` SELECT * FROM `coa_whelp_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 111262;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 111262;
INSERT INTO `creature_template_model` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureId` = 111262;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 111262;
INSERT INTO `creature_template_movement` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 111262;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 111262;
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 111262;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 111262;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` = 11262;
UPDATE `coa_whelp_copy` SET `entry` = 111262;
DELETE FROM `creature_template_addon` WHERE `entry` = 111262;
INSERT INTO `creature_template_addon` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;

DROP TEMPORARY TABLE IF EXISTS `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template` WHERE `entry` = 11262;
UPDATE `coa_whelp_copy` SET `entry` = 211262, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
INSERT INTO `creature_template` SELECT * FROM `coa_whelp_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 211262;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 211262;
INSERT INTO `creature_template_model` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureId` = 211262;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 211262;
INSERT INTO `creature_template_movement` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 211262;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 211262;
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 211262;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 211262;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` = 11262;
UPDATE `coa_whelp_copy` SET `entry` = 211262;
DELETE FROM `creature_template_addon` WHERE `entry` = 211262;
INSERT INTO `creature_template_addon` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;

DROP TEMPORARY TABLE IF EXISTS `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template` WHERE `entry` = 11262;
UPDATE `coa_whelp_copy` SET `entry` = 311262, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
INSERT INTO `creature_template` SELECT * FROM `coa_whelp_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 311262;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 311262;
INSERT INTO `creature_template_model` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureId` = 311262;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 311262;
INSERT INTO `creature_template_movement` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 311262;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 311262;
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` = 11262;
UPDATE `coa_whelp_copy` SET `CreatureID` = 311262;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 311262;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;
CREATE TEMPORARY TABLE `coa_whelp_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` = 11262;
UPDATE `coa_whelp_copy` SET `entry` = 311262;
DELETE FROM `creature_template_addon` WHERE `entry` = 311262;
INSERT INTO `creature_template_addon` SELECT * FROM `coa_whelp_copy`;
DROP TEMPORARY TABLE `coa_whelp_copy`;

UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `HealthModifier` = 2.933333 WHERE `entry` = 111262;
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `HealthModifier` = 4.414667 WHERE `entry` = 211262;
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `HealthModifier` = 6.438667 WHERE `entry` = 311262;
UPDATE `creature_template` SET `difficulty_entry_1` = 111262, `difficulty_entry_2` = 211262, `difficulty_entry_3` = 311262 WHERE `entry` = 11262;

-- Onyxia: health per player x 0.7 on every difficulty.
DELETE FROM `coa_boss_flex` WHERE `entry` = 10184;
INSERT INTO `coa_boss_flex` VALUES (10184, 589441, 785921, 1182879, 1724720, 'Onyxia: Normal = Heroic x 0.750 (set), Heroic measured, Mythic = Heroic x 1.505 (pattern), Ascended = Heroic x 2.195 (pattern); all x 0.7 (2026-11-25)');
