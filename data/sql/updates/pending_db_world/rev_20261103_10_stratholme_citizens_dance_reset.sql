-- Stratholme: a Ghostly Citizen (10385) or Spectral Citizen (10384) that is fighting resets when a player dances with
-- it, once per citizen, as on Ascension (#9896, #10636). Out of combat they keep answering /dance with a dance.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (10384, 10385) AND `source_type` = 0 AND `id` = 30;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10384, 0, 30, 0, 22, 4, 100, 257, 34, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectral Citizen - On Emote Received Dance (In Combat) - Evade (No Repeat)'),
(10385, 0, 30, 0, 22, 4, 100, 257, 34, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Dance (In Combat) - Evade (No Repeat)');
