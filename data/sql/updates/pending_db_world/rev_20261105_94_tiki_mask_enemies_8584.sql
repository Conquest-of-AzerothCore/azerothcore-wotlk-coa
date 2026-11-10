-- #8584/#8781/#8945: smashing a Tiki Mask in Zeb'Goro summons the hostile mask again, and killing it gives the
-- quest credit. Level 3 and 134/100/134 health from Bronzebeard Questie; Hellfire 256753 on the Chattering and
-- Possessed masks from Descension's live combat capture (descension-server b18d7ee7).
UPDATE `creature_template`
SET `minlevel` = 3, `maxlevel` = 3, `faction` = 14, `unit_flags` = 0, `flags_extra` = 0, `HealthModifier` = 1.8873
WHERE `entry` IN (161854, 161856);
UPDATE `creature_template`
SET `minlevel` = 3, `maxlevel` = 3, `faction` = 14, `unit_flags` = 0, `flags_extra` = 0, `HealthModifier` = 1.4084
WHERE `entry` = 161855;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (161855, 161856);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161855, 161856) AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300535, 2300536, 2300537) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300535, 1, 0, 1, 8, 0, 100, 0, 256719, 0, 0, 0, 0, 0, 12, 161854, 2, 60000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Enchanted Tiki Mask - On Spell Hit - Summon Enchanted Tiki Mask'),
(2300535, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Enchanted Tiki Mask - Linked - Despawn after the cast'),
(2300536, 1, 0, 1, 8, 0, 100, 0, 256719, 0, 0, 0, 0, 0, 12, 161855, 2, 60000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chattering Tiki Mask - On Spell Hit - Summon Chattering Tiki Mask'),
(2300536, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chattering Tiki Mask - Linked - Despawn after the cast'),
(2300537, 1, 0, 1, 8, 0, 100, 0, 256719, 0, 0, 0, 0, 0, 12, 161856, 2, 60000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Possessed Tiki Mask - On Spell Hit - Summon Possessed Tiki Mask'),
(2300537, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Possessed Tiki Mask - Linked - Despawn after the cast'),
(161855, 0, 0, 0, 0, 0, 100, 0, 3000, 5000, 18000, 22000, 0, 0, 11, 256753, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chattering Tiki Mask - In Combat - Cast Hellfire'),
(161856, 0, 0, 0, 0, 0, 100, 0, 3000, 5000, 18000, 22000, 0, 0, 11, 256753, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Possessed Tiki Mask - In Combat - Cast Hellfire');
