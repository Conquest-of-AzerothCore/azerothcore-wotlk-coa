-- Anger Not Easily Appeased (175096): only pacifying a Furious Gilded Treant (164301) with the
-- Magic Crystal (Golden Tranquility 365042) counts; killing it no longer gives kill credit
INSERT INTO `creature_template` (`entry`, `name`, `faction`, `unit_class`, `unit_flags`, `type`)
VALUES (445304, 'Furious Gilded Treant Pacified Credit', 35, 1, 2, 7) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 445304;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(445304, 0, 15485, 1, 1);

UPDATE `quest_template` SET `RequiredNpcOrGo1` = 445304 WHERE `ID` = 175096;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164301 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164301, 0, 0, 1, 8, 0, 100, 0, 365042, 0, 3000, 3000, 0, 0, 33, 445304, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - On Spellhit Golden Tranquility - Quest Credit'),
(164301, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 2000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Linked - Despawn In 2 s'),
(164301, 0, 100, 0, 0, 0, 100, 0, 5000, 9000, 14000, 20000, 0, 0, 11, 365118, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - In Combat - Cast War Stomp'),
(164301, 0, 101, 0, 2, 0, 100, 1, 0, 30, 0, 0, 0, 0, 11, 365144, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Between 0-30% Health - Cast Enrage');
