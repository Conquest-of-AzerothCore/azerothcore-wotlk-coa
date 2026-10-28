-- Heroic and Mythic templates for the dungeon bosses that had none, so they ran with their Normal values
-- and loot on every difficulty: Shadowpriest Sezz'ziz, Grubbis, Nekrum Gutchewer, Avatar of Hakkar,
-- Baron Aquanis, Theldren, Zelemar the Wrathful, Apothecary Hummel. Built like rev_20260926_00 (copies at
-- entry + 100000 / + 200000 with their model, movement, resistance, spell and addon rows), level 63 like
-- the other Heroic/Mythic bosses and their average damage (Heroic 18.38, Mythic 39.32); Apothecary Hummel
-- is a level 82 holiday boss and keeps his own level and damage.
-- Health without a coa_dungeon_health row follows the model for non-final bosses (Mythic 541,700,
-- Heroic / 1.30); Sezz'ziz, Grubbis, Nekrum and Zelemar already have rows.

DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template` WHERE `entry` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 100000, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `AIName` = '', `ScriptName` = '';
DELETE FROM `creature_template` WHERE `entry` IN (SELECT `entry` FROM `coa_dungeon_copy`);
INSERT INTO `creature_template` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (7275+100000, 7361+100000, 7796+100000, 8443+100000, 12876+100000, 16059+100000, 17830+100000, 36296+100000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_model` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (7275+100000, 7361+100000, 7796+100000, 8443+100000, 12876+100000, 16059+100000, 17830+100000, 36296+100000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureId` = `CreatureId` + 100000;
INSERT INTO `creature_template_movement` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` IN (7275+100000, 7361+100000, 7796+100000, 8443+100000, 12876+100000, 16059+100000, 17830+100000, 36296+100000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (7275+100000, 7361+100000, 7796+100000, 8443+100000, 12876+100000, 16059+100000, 17830+100000, 36296+100000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_addon` WHERE `entry` IN (7275+100000, 7361+100000, 7796+100000, 8443+100000, 12876+100000, 16059+100000, 17830+100000, 36296+100000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 100000;
INSERT INTO `creature_template_addon` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template` WHERE `entry` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 200000, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `AIName` = '', `ScriptName` = '';
DELETE FROM `creature_template` WHERE `entry` IN (SELECT `entry` FROM `coa_dungeon_copy`);
INSERT INTO `creature_template` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (7275+200000, 7361+200000, 7796+200000, 8443+200000, 12876+200000, 16059+200000, 17830+200000, 36296+200000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 200000;
INSERT INTO `creature_template_model` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (7275+200000, 7361+200000, 7796+200000, 8443+200000, 12876+200000, 16059+200000, 17830+200000, 36296+200000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureId` = `CreatureId` + 200000;
INSERT INTO `creature_template_movement` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` IN (7275+200000, 7361+200000, 7796+200000, 8443+200000, 12876+200000, 16059+200000, 17830+200000, 36296+200000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 200000;
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (7275+200000, 7361+200000, 7796+200000, 8443+200000, 12876+200000, 16059+200000, 17830+200000, 36296+200000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 200000;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
DELETE FROM `creature_template_addon` WHERE `entry` IN (7275+200000, 7361+200000, 7796+200000, 8443+200000, 12876+200000, 16059+200000, 17830+200000, 36296+200000);
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 200000;
INSERT INTO `creature_template_addon` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

UPDATE `creature_template` SET `difficulty_entry_1` = `entry` + 100000, `difficulty_entry_2` = `entry` + 200000
WHERE `entry` IN (7275, 7361, 7796, 8443, 12876, 16059, 17830, 36296);
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 18.38
WHERE `entry` IN (107275, 107361, 107796, 108443, 112876, 116059, 117830);
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 39.32
WHERE `entry` IN (207275, 207361, 207796, 208443, 212876, 216059, 217830);

DELETE FROM `coa_dungeon_health` WHERE `creature_entry` IN (8443, 12876, 16059);
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(109, 2, 8443, 541700, 'model', 'non-final boss model; Avatar of Hakkar'),
(109, 1, 8443, 416692, 'model', 'Heroic from Mythic; non-final boss model; Avatar of Hakkar'),
(48, 2, 12876, 541700, 'model', 'non-final boss model; Baron Aquanis'),
(48, 1, 12876, 416692, 'model', 'Heroic from Mythic; non-final boss model; Baron Aquanis'),
(230, 2, 16059, 541700, 'model', 'non-final boss model; Theldren'),
(230, 1, 16059, 416692, 'model', 'Heroic from Mythic; non-final boss model; Theldren');
