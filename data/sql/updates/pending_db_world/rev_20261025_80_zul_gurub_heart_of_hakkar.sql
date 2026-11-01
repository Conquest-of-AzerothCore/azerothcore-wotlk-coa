-- Zul'Gurub: the Heart of Hakkar is creature 92005, as in the CoA combat log of 2026-08-02 and the
-- client creature cache (rank 3, model 28887, HealthModifier 17.55, ManaModifier 1.755; hostile per
-- db.exil.es). boss_hakkar_coa summons it instead of the stand-in 9780022 from 14_zg.sql.
DROP TEMPORARY TABLE IF EXISTS `zg_heart`;
CREATE TEMPORARY TABLE `zg_heart` AS SELECT * FROM `creature_template` WHERE `entry` = 15069;
UPDATE `zg_heart` SET `entry` = 92005;
INSERT INTO `creature_template` SELECT * FROM `zg_heart`
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `zg_heart`;
UPDATE `creature_template` SET `name` = 'Heart of Hakkar', `difficulty_entry_1` = 0, `difficulty_entry_2` = 0,
    `difficulty_entry_3` = 0, `minlevel` = 63, `maxlevel` = 63, `faction` = 28, `rank` = 3, `unit_flags` = 0,
    `AIName` = '', `HealthModifier` = 17.55, `ManaModifier` = 1.755, `lootid` = 0, `pickpocketloot` = 0,
    `skinloot` = 0, `ScriptName` = 'npc_heart_of_hakkar_coa', `VerifiedBuild` = 0
 WHERE `entry` = 92005;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 92005;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(92005, 0, 28887, 1, 1, 0);
