DELETE FROM `creature_template` WHERE `entry` = 9604829;
DROP TEMPORARY TABLE IF EXISTS `coa_copy_9604829`;
CREATE TEMPORARY TABLE `coa_copy_9604829` AS SELECT * FROM `creature_template` WHERE `entry` = 16697;
UPDATE `coa_copy_9604829` SET `entry` = 9604829, `name` = 'Shadow Pool', `subname` = NULL, `minlevel` = 61, `maxlevel` = 61, `faction` = 14, `HealthModifier` = 1, `unit_flags` = 33554434, `AIName` = 'SmartAI', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_copy_9604829`;
DROP TEMPORARY TABLE `coa_copy_9604829`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9604829;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9604829, 0, 11686, 1, 1, 0);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 9604829 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (9604829, 0, 0, 0, 37, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Pool (Heroic) - On AI Init - Set Passive'),
    (9604829, 0, 1, 0, 60, 0, 100, 0, 0, 0, 1000, 1000, 0, 0, 11, 64208, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Pool (Heroic) - Every second - Cast ''Consumption'' (5 yd, matches the rift)'),
    (9604829, 0, 2, 0, 60, 0, 100, 0, 0, 0, 6000, 6000, 0, 0, 11, 2102728, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Pool (Heroic) - Every 6 s - Cast ''Summon Nightmare Rift'' (Ascension rift visual)');
DELETE FROM `coa_dungeon_creature_damage` WHERE `entry` = 9604829;
INSERT INTO `coa_dungeon_creature_damage` (`entry`, `spell_id`, `multiplier`, `comment`) VALUES (9604829, 64208, 0.4, 'Aku''mai Shadow Pool (Heroic): Consumption about 400 per second');

DELETE FROM `creature_template` WHERE `entry` = 9504829;
DROP TEMPORARY TABLE IF EXISTS `coa_copy_9504829`;
CREATE TEMPORARY TABLE `coa_copy_9504829` AS SELECT * FROM `creature_template` WHERE `entry` = 16697;
UPDATE `coa_copy_9504829` SET `entry` = 9504829, `name` = 'Shadow Pool', `subname` = NULL, `minlevel` = 61, `maxlevel` = 61, `faction` = 14, `HealthModifier` = 1, `unit_flags` = 33554434, `AIName` = 'SmartAI', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_copy_9504829`;
DROP TEMPORARY TABLE `coa_copy_9504829`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9504829;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9504829, 0, 11686, 1, 1, 0);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 9504829 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (9504829, 0, 0, 0, 37, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Pool (Mythic) - On AI Init - Set Passive'),
    (9504829, 0, 1, 0, 60, 0, 100, 0, 0, 0, 1000, 1000, 0, 0, 11, 64208, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Pool (Mythic) - Every second - Cast ''Consumption'' (5 yd, matches the rift)'),
    (9504829, 0, 2, 0, 60, 0, 100, 0, 0, 0, 6000, 6000, 0, 0, 11, 2102728, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Pool (Mythic) - Every 6 s - Cast ''Summon Nightmare Rift'' (Ascension rift visual)');
DELETE FROM `coa_dungeon_creature_damage` WHERE `entry` = 9504829;
INSERT INTO `coa_dungeon_creature_damage` (`entry`, `spell_id`, `multiplier`, `comment`) VALUES (9504829, 64208, 0.52, 'Aku''mai Shadow Pool (Mythic): Consumption about 520 per second');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 4829 AND `source_type` = 0 AND `id` IN (9020, 9021);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (4829, 0, 9020, 0, 0, 0, 100, 4, 10000, 12000, 25000, 25000, 0, 0, 12, 9604829, 3, 20000, 0, 0, 0, 17, 0, 60, 3, 0, 0, 0, 0, 0, 'Aku''mai - Heroic - In Combat (first 10-12 s, then every 25 s) - Summon a Shadow Pool under 3 random players'),
    (4829, 0, 9021, 0, 0, 0, 100, 8, 10000, 12000, 25000, 25000, 0, 0, 12, 9504829, 3, 20000, 0, 0, 0, 17, 0, 60, 3, 0, 0, 0, 0, 0, 'Aku''mai - Mythic - In Combat (first 10-12 s, then every 25 s) - Summon a Shadow Pool under 3 random players');
