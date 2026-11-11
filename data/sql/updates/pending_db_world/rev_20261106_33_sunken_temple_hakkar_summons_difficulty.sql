-- Sunken Temple: the Hakkari Bloodkeepers (8438) the Shade of Hakkar summons and the Hakkari Minions (8437) of the
-- summoning circles had no Heroic or Mythic template, so they kept their Normal level and health (#11440). They get
-- copies as the other dungeon creatures did in rev_20260926_00 (+100000 Heroic, +200000 Mythic). Exiles lists no
-- variant for them: the levels are an estimate, the Bloodkeeper at 61 like the Nightmare Suppressor (49 -> 61) and the
-- Minion twelve levels up at 57-58.
DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template` WHERE `entry` IN (8437, 8438);
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 100000, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0,
    `difficulty_entry_3` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_dungeon_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
UPDATE `coa_dungeon_copy` SET `entry` = `entry` + 100000;
INSERT INTO `creature_template` SELECT * FROM `coa_dungeon_copy`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` IN (8437, 8438);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (108437, 108438, 208437, 208438);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_model` SELECT * FROM `coa_dungeon_copy`;
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_model` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

DROP TEMPORARY TABLE IF EXISTS `coa_dungeon_copy`;
CREATE TEMPORARY TABLE `coa_dungeon_copy` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` IN (8437, 8438);
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (108437, 108438, 208437, 208438);
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_dungeon_copy`;
UPDATE `coa_dungeon_copy` SET `CreatureID` = `CreatureID` + 100000;
INSERT INTO `creature_template_spell` SELECT * FROM `coa_dungeon_copy`;
DROP TEMPORARY TABLE `coa_dungeon_copy`;

UPDATE `creature_template` SET `minlevel` = 61, `maxlevel` = 61 WHERE `entry` IN (108438, 208438);
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 58 WHERE `entry` IN (108437, 208437);
UPDATE `creature_template` SET `difficulty_entry_1` = `entry` + 100000, `difficulty_entry_2` = `entry` + 200000
WHERE `entry` IN (8437, 8438);
