-- Lord Victor Nefarius and Nefarian as Ascension rebuilt them; see boss_nefarian_coa.cpp.
--
-- The Shadow Clone of Dominion exists nowhere in Ascension's data - its spells
-- do (2111279-2111282), the creature does not. It is a new one, 9780021,
-- copied from the Blackwing Warlock; the script dresses it in its owner's shape.
--
-- Undo: SET `ScriptName` back to boss_victor_nefarius / boss_nefarian, delete
-- 9780021 and the spell script row.

DELETE FROM `creature_template` WHERE `entry` = 9780021;
DROP TEMPORARY TABLE IF EXISTS `nef_clone`;
CREATE TEMPORARY TABLE `nef_clone` AS SELECT * FROM `creature_template` WHERE `entry` = 12459;
UPDATE `nef_clone` SET `entry` = 9780021, `name` = 'Shadow Clone', `subname` = 'Stolen Soul',
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = 'npc_nefarian_shadow_clone', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `nef_clone`;
DROP TEMPORARY TABLE `nef_clone`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9780021;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 9780021, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, 0 FROM `creature_template_model` WHERE `CreatureID` = 12459;

UPDATE `creature_template` SET `ScriptName` = 'boss_victor_nefarius_coa' WHERE `entry` = 10162;
UPDATE `creature_template` SET `ScriptName` = 'boss_nefarian_coa'        WHERE `entry` = 11583;

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_nefarius_coa_veil';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2111288, 'spell_nefarius_coa_veil');
