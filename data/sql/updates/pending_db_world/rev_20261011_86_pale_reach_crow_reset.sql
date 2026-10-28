UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164944;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164944 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `action_type`, `action_param1`, `action_param2`, `target_type`, `comment`)
VALUES
(164944, 0, 0, 0, 7, 0, 100, 0, 91, 1, 0, 1,
 'Possessed Crow - On evade - Clear sitting state before returning home; addon restores perch on arrival');
