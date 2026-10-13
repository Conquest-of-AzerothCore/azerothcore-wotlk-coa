DELETE FROM `smart_scripts` WHERE `entryorguid` = 164002 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `target_type`, `comment`)
VALUES
(164002, 0, 0, 0, 10, 0, 100, 256, 1, 15, 300000, 300000, 1, 80, 16400200, 0, 2, 1,
 'Captain Hedgar - Player approaches - Start manor exchange with five-minute cooldown'),
(164002, 0, 1, 0, 10, 0, 100, 256, 1, 20, 300000, 300000, 1, 1, 1, 0, 0, 7,
 'Captain Hedgar - Player with the Ealdir plot uncovered approaches - Call them over every five minutes');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 16400200 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `action_type`, `action_param1`,
    `target_type`, `target_param1`, `target_param2`, `comment`)
VALUES
(16400200, 9, 0, 0, 0, 0, 100, 0, 0, 0, 1, 0, 1, 0, 0,
 'Manor exchange - Captain Hedgar gives orders'),
(16400200, 9, 1, 0, 0, 0, 100, 0, 5000, 5000, 1, 0, 19, 164210, 30,
 'Manor exchange - Cadmilla answers the captain after five seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164210 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `action_type`, `action_param1`, `target_type`, `comment`)
VALUES
(164210, 0, 1, 0, 19, 0, 100, 0, 175004, 1, 1, 7,
 'Cadmilla - On Notes of a Conspiracy accepted - Say quest hint');
