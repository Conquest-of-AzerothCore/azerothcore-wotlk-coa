-- "The Crusaders of Hallow Wind": "Crusaders found" counts an invisible helper that did not exist. No trigger zone is near
-- the crusaders Father Amrod sent (the nearest is over 200 yards off), so reaching them counts: a player who comes within
-- 15 yards of a Hallow Wind Crusader gets the credit.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `flags_extra`) VALUES
(164503, '[KC] Crusaders found', 1, 1, 35, 33554432, 128) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `flags_extra` = VALUES(`flags_extra`);
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164209;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164209 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164209, 0, 0, 0, 10, 0, 100, 0, 2, 15, 3000, 3000, 1, 0, 33, 164503, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hallow Wind Crusader - Player Within 15 Yards - Quest Credit ''Crusaders found''');
