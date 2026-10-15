-- The Zul'Gurub bosses with Ascension's spells; see the boss_*_coa.cpp files.
--
-- Stock scripts stay for Gahz'ranka (no Ascension spells in the client data),
-- Hazza'rah, Renataki and Wushoolay (the same), and for every add.
--
-- The Heart of Hakkar the fight needs is a new creature, 9780022: the stock
-- one (15069) belongs to the Yojamba Isle event and despawns itself out of
-- combat. It is copied from it and fights on Hakkar's side.
--
-- Undo: SET `ScriptName` back to the stock names, delete 9780022 and the
-- spell script rows.

UPDATE `creature_template` SET `ScriptName` = 'boss_venoxis_coa'  WHERE `entry` = 14507;
UPDATE `creature_template` SET `ScriptName` = 'boss_jeklik_coa'   WHERE `entry` = 14517;
UPDATE `creature_template` SET `ScriptName` = 'boss_marli_coa'    WHERE `entry` = 14510;
UPDATE `creature_template` SET `ScriptName` = 'boss_thekal_coa'   WHERE `entry` = 14509;
UPDATE `creature_template` SET `ScriptName` = 'boss_arlokk_coa'   WHERE `entry` = 14515;
UPDATE `creature_template` SET `ScriptName` = 'boss_mandokir_coa' WHERE `entry` = 11382;
UPDATE `creature_template` SET `ScriptName` = 'boss_jindo_coa'    WHERE `entry` = 11380;
UPDATE `creature_template` SET `ScriptName` = 'boss_hakkar_coa'   WHERE `entry` = 14834;
UPDATE `creature_template` SET `ScriptName` = 'boss_grilek_coa'   WHERE `entry` = 15082;

DELETE FROM `creature_template` WHERE `entry` = 9780022;
DROP TEMPORARY TABLE IF EXISTS `zg_heart`;
CREATE TEMPORARY TABLE `zg_heart` AS SELECT * FROM `creature_template` WHERE `entry` = 15069;
UPDATE `zg_heart` SET `entry` = 9780022, `minlevel` = 63, `maxlevel` = 63,
    `faction` = (SELECT `faction` FROM `creature_template` WHERE `entry` = 14834),
    `unit_flags` = 0, `AIName` = '', `ScriptName` = 'npc_heart_of_hakkar_coa',
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `zg_heart`;
DROP TEMPORARY TABLE `zg_heart`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9780022;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 9780022, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, 0 FROM `creature_template_model` WHERE `CreatureID` = 15069;

-- Parasitic Poison (all four difficulties): dispelled, a serpent breaks out.
-- Corrupted Blood (all four): heals Hakkar, leaves a pool.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_venoxis_coa_parasitic_poison', 'spell_hakkar_coa_corrupted_blood');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118041, 'spell_venoxis_coa_parasitic_poison'),
(2118042, 'spell_venoxis_coa_parasitic_poison'),
(2118043, 'spell_venoxis_coa_parasitic_poison'),
(2118044, 'spell_venoxis_coa_parasitic_poison'),
(2118601, 'spell_hakkar_coa_corrupted_blood'),
(2118602, 'spell_hakkar_coa_corrupted_blood'),
(2118603, 'spell_hakkar_coa_corrupted_blood'),
(2118604, 'spell_hakkar_coa_corrupted_blood');
