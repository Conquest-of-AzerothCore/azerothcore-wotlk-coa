-- The Temple of Ahn'Qiraj bosses as Ascension rebuilt them; see the boss_*_coa.cpp files.
--
-- Stock scripts stay for the Bug Trio, Fankriss and Viscidus: Ascension has no
-- spells for them. The flesh tentacles, the portals, Ouro's mounds and spawner,
-- and every area trigger keep their stock scripts too.
--
-- Skeram's five nightmare creatures are new (9780024-9780028): the data has
-- their phases and their fears, not the creatures. Copied from the Vekniss
-- Wasp; the Monstrosity wears Lady Prestor's model. Their health is set by
-- Skeram when they appear.
--
-- Undo: SET the stock ScriptNames back (boss_skeram, boss_sartura,
-- npc_sartura_royal_guard, boss_huhuran, boss_veknilash, boss_veklor,
-- boss_ouro, boss_eye_of_cthun, boss_cthun, npc_eye_tentacle, npc_claw_tentacle,
-- npc_giant_claw_tentacle, npc_giant_eye_tentacle) and delete 9780024-9780028.

UPDATE `creature_template` SET `ScriptName` = 'boss_skeram_coa' WHERE `entry` = 15263;
UPDATE `creature_template` SET `ScriptName` = 'boss_sartura_coa' WHERE `entry` = 15516;
UPDATE `creature_template` SET `ScriptName` = 'npc_sartura_phantom_coa' WHERE `entry` = 15984;
UPDATE `creature_template` SET `ScriptName` = 'boss_huhuran_coa' WHERE `entry` = 15509;
UPDATE `creature_template` SET `ScriptName` = 'boss_veknilash_coa' WHERE `entry` = 15275;
UPDATE `creature_template` SET `ScriptName` = 'boss_veklor_coa' WHERE `entry` = 15276;
UPDATE `creature_template` SET `ScriptName` = 'boss_ouro_coa' WHERE `entry` = 15517;
UPDATE `creature_template` SET `ScriptName` = 'boss_eye_of_cthun_coa' WHERE `entry` = 15589;
UPDATE `creature_template` SET `ScriptName` = 'boss_cthun_coa' WHERE `entry` = 15727;
UPDATE `creature_template` SET `ScriptName` = 'npc_eye_tentacle_coa' WHERE `entry` = 15726;
UPDATE `creature_template` SET `ScriptName` = 'npc_claw_tentacle_coa' WHERE `entry` = 15725;
UPDATE `creature_template` SET `ScriptName` = 'npc_giant_claw_tentacle_coa' WHERE `entry` = 15728;
UPDATE `creature_template` SET `ScriptName` = 'npc_giant_eye_tentacle_coa' WHERE `entry` = 15334;

DELETE FROM `creature_template` WHERE `entry` IN (9780024,9780025,9780026,9780027,9780028);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9780024,9780025,9780026,9780027,9780028);
DROP TEMPORARY TABLE IF EXISTS `aq_dread`;
CREATE TEMPORARY TABLE `aq_dread` AS SELECT * FROM `creature_template` WHERE `entry` = 15236;
UPDATE `aq_dread` SET `entry` = 9780024, `name` = 'Nightmare Murloc', `subname` = NULL, `minlevel` = 63, `maxlevel` = 63,
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = 'npc_skeram_nightmare_coa', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `aq_dread`;
DROP TEMPORARY TABLE `aq_dread`;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9780024, 0, 1305, 1.2, 1, 0);
DROP TEMPORARY TABLE IF EXISTS `aq_dread`;
CREATE TEMPORARY TABLE `aq_dread` AS SELECT * FROM `creature_template` WHERE `entry` = 15236;
UPDATE `aq_dread` SET `entry` = 9780025, `name` = 'Nightmare Spider', `subname` = NULL, `minlevel` = 63, `maxlevel` = 63,
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = 'npc_skeram_nightmare_coa', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `aq_dread`;
DROP TEMPORARY TABLE `aq_dread`;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9780025, 0, 6808, 1.0, 1, 0);
DROP TEMPORARY TABLE IF EXISTS `aq_dread`;
CREATE TEMPORARY TABLE `aq_dread` AS SELECT * FROM `creature_template` WHERE `entry` = 15236;
UPDATE `aq_dread` SET `entry` = 9780026, `name` = 'Nightmare Bee', `subname` = NULL, `minlevel` = 63, `maxlevel` = 63,
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = 'npc_skeram_nightmare_coa', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `aq_dread`;
DROP TEMPORARY TABLE `aq_dread`;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9780026, 0, 15335, 1.0, 1, 0);
DROP TEMPORARY TABLE IF EXISTS `aq_dread`;
CREATE TEMPORARY TABLE `aq_dread` AS SELECT * FROM `creature_template` WHERE `entry` = 15236;
UPDATE `aq_dread` SET `entry` = 9780027, `name` = 'Nightmare Cat', `subname` = NULL, `minlevel` = 63, `maxlevel` = 63,
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = 'npc_skeram_nightmare_coa', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `aq_dread`;
DROP TEMPORARY TABLE `aq_dread`;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9780027, 0, 613, 1.2, 1, 0);
DROP TEMPORARY TABLE IF EXISTS `aq_dread`;
CREATE TEMPORARY TABLE `aq_dread` AS SELECT * FROM `creature_template` WHERE `entry` = 15236;
UPDATE `aq_dread` SET `entry` = 9780028, `name` = 'Nightmarish Monstrosity', `subname` = NULL, `minlevel` = 63, `maxlevel` = 63,
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `AIName` = '', `ScriptName` = 'npc_skeram_nightmare_coa', `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0;
INSERT INTO `creature_template` SELECT * FROM `aq_dread`;
DROP TEMPORARY TABLE `aq_dread`;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9780028, 0, 8769, 1.3, 1, 0);
