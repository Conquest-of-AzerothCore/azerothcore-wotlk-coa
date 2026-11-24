-- #12923: when High Inquisitor Whitemane evades with evade disabled (a Heroic leash breach during Deep Sleep),
-- only SMART_EVENT_EVADE runs, so the group stayed asleep for the 60 s aura; wake players and pets on evade
UPDATE `smart_scripts` SET `link` = 20 WHERE `entryorguid` = 3977 AND `source_type` = 0 AND `id` = 11;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 3977 AND `source_type` = 0 AND `id` IN (20, 21);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `action_type`, `action_param1`, `target_type`, `target_param1`, `target_param2`, `comment`) VALUES
(3977, 0, 20, 21, 61, 0, 100, 0, 28, 9256, 18, 100, 0, 'High Inquisitor Whitemane - On Evade - Remove Aura ''Deep Sleep'' from Players'),
(3977, 0, 21, 12, 61, 0, 100, 0, 28, 9256, 11, 0, 100, 'High Inquisitor Whitemane - On Evade - Remove Aura ''Deep Sleep'' from Creatures');
