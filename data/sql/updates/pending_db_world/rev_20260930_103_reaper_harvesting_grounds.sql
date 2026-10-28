INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`,
`unit_flags`, `type`, `MovementType`, `flags_extra`, `ScriptName`) VALUES
(300662, 'Harvesting Grounds', 80, 80, 35, 1, 33554434, 10, 0, 128, 'npc_ascension_reaper_harvesting_grounds')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`),
`maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`),
`unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `MovementType` = VALUES(`MovementType`),
`flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 300662;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(300662, 0, 11686, 1, 1);

DELETE FROM `spell_script_names` WHERE `spell_id` = 705413 AND
`ScriptName` = 'aura_ascension_reaper_harvesting_grounds';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705413, 'aura_ascension_reaper_harvesting_grounds');
