-- Hold the Anchors (9417110): wave mobs leave only by dying, and a new Q10 accept sends an escorting Khadgar home
UPDATE `smart_scripts` SET `action_param2` = 6
WHERE `source_type` = 9 AND `action_type` = 12 AND `action_param2` = 4
  AND `entryorguid` IN (941700401, 941700411, 941700421, 941700431, 941700432, 941700441, 941700442,
                        941704001, 941704002, 941704003);

UPDATE `smart_scripts` SET `link` = 7 WHERE `entryorguid` = 9417003 AND `source_type` = 0 AND `id` = 2;

DELETE FROM `smart_scripts` WHERE (`entryorguid` = 9417003 AND `source_type` = 0 AND `id` = 7)
                               OR (`entryorguid` = 9417004 AND `source_type` = 0 AND `id` = 79);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(9417003, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 10, 9417100, 9417004, 0, 0, 0, 0, 0, 0, 'Khadgar (Field) - Linked - Set data 1 = 1 on the escort Khadgar (guid 9417100): a new Q10 run'),
(9417004, 0, 79, 0, 38, 3, 100, 0, 1, 1, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Khadgar (Escort) - Data 1 = 1 while escorting or channelling - Despawn (back at the camp with gossip in 30 s)');
