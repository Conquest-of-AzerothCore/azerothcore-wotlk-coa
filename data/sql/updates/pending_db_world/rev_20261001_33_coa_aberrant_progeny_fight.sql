-- Aberrant Progeny 161757 (The True Heir of the Cains), from CoA footage described by the playtester: it breathes
-- fire in a frontal cone (Flame Breath 256748) behind CoA's red cone telegraph (354902), holding its aim so the cone
-- can be dodged. At 30% health it vanishes and four copies of it rise around the summoning circle, each speaking and
-- casting Fel Explosion 256749; each copy knocks the players back as it dies (Fel Explosion 256750). When all four
-- are dead the Progeny returns, and near death it says "Sad... ness...". The fight is npc_coa_aberrant_progeny in
-- src/server/coa/AscensionCainManor.cpp; the copies (9300259) keep SmartAI. The spells are CoA's own; timings and
-- the copy count are INFERRED from the footage.
UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_coa_aberrant_progeny' WHERE `entry` = 161757;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9300259, 'Aberrant Progeny', NULL, 0, 7, 7, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 3, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `HealthModifier` = VALUES(`HealthModifier`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9300259;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(9300259, 0, 76125, 0.6, 1);
DELETE FROM `creature_text` WHERE `CreatureID` IN (161757, 9300259);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(161757, 0, 0, 'Sad... ness...', 12, 100, 'Aberrant Progeny - near death (CoA footage)'),
(9300259, 0, 0, 'Wh... y...?', 12, 50, 'Aberrant Progeny copy - summoned (CoA footage)'),
(9300259, 0, 1, 'Play... with... me...', 12, 50, 'Aberrant Progeny copy - summoned (CoA footage)');
DELETE FROM `smart_scripts` WHERE (`entryorguid` IN (161757, 9300259) AND `source_type` = 0) OR (`entryorguid` = 16175700 AND `source_type` = 9);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(9300259, 0, 0, 1, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aberrant Progeny copy - Just Summoned - Say Line 0'),
(9300259, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 103, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aberrant Progeny copy - Linked - Root'),
(9300259, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 256749, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aberrant Progeny copy - Linked - Cast Fel Explosion'),
(9300259, 0, 3, 0, 0, 0, 100, 0, 16000, 16000, 16000, 16000, 0, 0, 11, 256749, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aberrant Progeny copy - In Combat - Cast Fel Explosion'),
(9300259, 0, 4, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 256750, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aberrant Progeny copy - On Death - Fel Explosion knockback');
