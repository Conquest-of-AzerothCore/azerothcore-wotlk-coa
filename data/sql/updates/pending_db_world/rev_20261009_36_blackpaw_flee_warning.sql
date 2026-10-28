-- Blackpaw Gnolls and Scavengers should warn nearby players when fleeing at low health (#336).
-- Preserve both complete SmartAI blocks, including the Scavenger's Pierce Armor action.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (16334, 16335) AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(16334, 0, 0, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0,
    25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    'Blackpaw Gnoll - Between 0-15% Health - Flee For Assist'),
(16335, 0, 0, 0, 9, 0, 100, 0, 0, 0, 45000, 45000, 0, 5,
    11, 6016, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Blackpaw Scavenger - Within 0-5 Range - Cast ''Pierce Armor'''),
(16335, 0, 1, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0,
    25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    'Blackpaw Scavenger - Between 0-15% Health - Flee For Assist');
