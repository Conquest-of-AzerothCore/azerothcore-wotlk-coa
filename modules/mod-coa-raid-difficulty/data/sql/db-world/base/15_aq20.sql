-- The Ruins of Ahn'Qiraj bosses as Ascension rebuilt them; see the boss_*_coa.cpp files.
--
-- Ayamiss keeps her stock script: Ascension has no spells for her.
--
-- General Rajaxx's officers and privates drop their SmartAI for one script,
-- npc_rajaxx_legion_coa, which gives each officer the ability his badge
-- teaches. They exist only in this instance.
--
-- The Sandreaver Broodling Kurinnaxx calls is a new creature, 9780023: the data
-- names it only in its acid's tooltip. Copied from the Hive'Zara Larva, with
-- the Sandreaver model at 60% size.
--
-- Undo: SET the stock ScriptNames back (boss_kurinnaxx, boss_rajaxx, boss_moam,
-- boss_buru, boss_ossirian, npc_buru_egg), AIName 'SmartAI' for the legion,
-- delete 9780023 and the spell script row.

UPDATE `creature_template` SET `ScriptName` = 'boss_kurinnaxx_coa' WHERE `entry` = 15348;
UPDATE `creature_template` SET `ScriptName` = 'boss_rajaxx_coa'    WHERE `entry` = 15341;
UPDATE `creature_template` SET `ScriptName` = 'boss_moam_coa'      WHERE `entry` = 15340;
UPDATE `creature_template` SET `ScriptName` = 'boss_buru_coa'      WHERE `entry` = 15370;
UPDATE `creature_template` SET `ScriptName` = 'boss_ossirian_coa'  WHERE `entry` = 15339;
UPDATE `creature_template` SET `ScriptName` = 'npc_buru_egg_coa'   WHERE `entry` = 15514;
UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_rajaxx_legion_coa'
 WHERE `entry` IN (15385, 15386, 15387, 15388, 15389, 15390, 15391, 15392, 15344);

DELETE FROM `creature_template` WHERE `entry` = 9780023;
DROP TEMPORARY TABLE IF EXISTS `aq_brood`;
CREATE TEMPORARY TABLE `aq_brood` AS SELECT * FROM `creature_template` WHERE `entry` = 15555;
UPDATE `aq_brood` SET `entry` = 9780023, `name` = 'Sandreaver Broodling', `subname` = NULL,
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = '', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `aq_brood`;
DROP TEMPORARY TABLE `aq_brood`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9780023;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES (9780023, 0, 3195, 0.6, 1, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_rajaxx_coa_reflective_shield';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2112325, 'spell_rajaxx_coa_reflective_shield');
