-- Heroic and Mythic templates for the six Ring of Law bosses (Gorosh the Dervish, Grizzle, Eviscerator, Ok'thor the
-- Breaker, Anub'shiah, Hedrum the Creeper), which had none, so they ran with their Normal values and loot on every
-- difficulty (#8360). Built like rev_20260926_00 (copies at entry + 100000 / + 200000 with their model, movement,
-- resistance, spell and addon rows), level 63 like the other Heroic/Mythic bosses (db.exil.es, dump of 2026-10-04:
-- "Level 63 Boss") and the average damage of rev_20261009_65 (Heroic 18.38, Mythic 39.32). The copies use their own
-- loot lists, written by rev_20261016_30. Health follows the rev_20261009_65 model for non-final bosses (Mythic
-- 541,700, Heroic / 1.30).

DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template` WHERE `entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 100000, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_dungeon_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (109027, 109028, 109029, 109030, 109031, 109032);
INSERT INTO `creature_template_model` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureId` = `CreatureId` + 100000;
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (109027, 109028, 109029, 109030, 109031, 109032);
INSERT INTO `creature_template_movement` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` IN (109027, 109028, 109029, 109030, 109031, 109032);
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (109027, 109028, 109029, 109030, 109031, 109032);
INSERT INTO `creature_template_spell` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 100000;
DELETE FROM `creature_template_addon` WHERE `entry` IN (109027, 109028, 109029, 109030, 109031, 109032);
INSERT INTO `creature_template_addon` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template` WHERE `entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 200000, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_dungeon_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 200000;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (209027, 209028, 209029, 209030, 209031, 209032);
INSERT INTO `creature_template_model` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureId` = `CreatureId` + 200000;
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (209027, 209028, 209029, 209030, 209031, 209032);
INSERT INTO `creature_template_movement` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 200000;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` IN (209027, 209028, 209029, 209030, 209031, 209032);
INSERT INTO `creature_template_resistance` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 200000;
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (209027, 209028, 209029, 209030, 209031, 209032);
INSERT INTO `creature_template_spell` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_addon` WHERE `entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 200000;
DELETE FROM `creature_template_addon` WHERE `entry` IN (209027, 209028, 209029, 209030, 209031, 209032);
INSERT INTO `creature_template_addon` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

UPDATE `creature_template` SET `difficulty_entry_1` = `entry` + 100000, `difficulty_entry_2` = `entry` + 200000
WHERE `entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 18.38, `lootid` = `entry`
WHERE `entry` IN (109027, 109028, 109029, 109030, 109031, 109032);
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 39.32, `lootid` = `entry`
WHERE `entry` IN (209027, 209028, 209029, 209030, 209031, 209032);

DELETE FROM `coa_dungeon_health` WHERE `map_id` = 230 AND `creature_entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(230, 2, 9027, 541700, 'model', 'non-final boss model; Gorosh the Dervish'),
(230, 1, 9027, 416692, 'model', 'Heroic from Mythic; non-final boss model; Gorosh the Dervish'),
(230, 2, 9028, 541700, 'model', 'non-final boss model; Grizzle'),
(230, 1, 9028, 416692, 'model', 'Heroic from Mythic; non-final boss model; Grizzle'),
(230, 2, 9029, 541700, 'model', 'non-final boss model; Eviscerator'),
(230, 1, 9029, 416692, 'model', 'Heroic from Mythic; non-final boss model; Eviscerator'),
(230, 2, 9030, 541700, 'model', 'non-final boss model; Ok''thor the Breaker'),
(230, 1, 9030, 416692, 'model', 'Heroic from Mythic; non-final boss model; Ok''thor the Breaker'),
(230, 2, 9031, 541700, 'model', 'non-final boss model; Anub''shiah'),
(230, 1, 9031, 416692, 'model', 'Heroic from Mythic; non-final boss model; Anub''shiah'),
(230, 2, 9032, 541700, 'model', 'non-final boss model; Hedrum the Creeper'),
(230, 1, 9032, 416692, 'model', 'Heroic from Mythic; non-final boss model; Hedrum the Creeper');

-- A Mark of Triumph per kill on Heroic and Mythic, as rev_20261016_30 (#7928) intended for the Ring of Law bosses;
-- they were left out because they are not in coa_dungeon_bosses (db.exil.es, dump of 2026-10-04: 1414502 at 100%).
DELETE FROM `coa_dungeon_mark_bosses` WHERE `entry` IN (9027, 9028, 9029, 9030, 9031, 9032);
INSERT INTO `coa_dungeon_mark_bosses` (`entry`) VALUES
(9027),
(9028),
(9029),
(9030),
(9031),
(9032);
