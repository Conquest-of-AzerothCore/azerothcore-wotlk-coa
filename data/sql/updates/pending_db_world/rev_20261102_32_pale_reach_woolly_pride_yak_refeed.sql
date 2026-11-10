-- Woolly Pride (175133): a fed Ealdfrost Yak becomes clickable again after 60 s. The timed event needs a maximum
-- delay at least as large as its minimum, or SmartAI skips the row at load and the yak stays unclickable.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164420 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `target_type`, `comment`) VALUES
(164420, 0, 0, 1, 8, 0, 100, 0, 9978001, 0, 0, 0, 33, 164420, 0, 0, 7, 'Ealdfrost Yak - On Fed - Quest Credit Yaks fed (175133)'),
(164420, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 81, 0, 0, 0, 1, 'Ealdfrost Yak - Linked - Remove Click Flag'),
(164420, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 1, 'Ealdfrost Yak - Linked - Create Timed Event 1 (60 s)'),
(164420, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 81, 16777216, 0, 0, 1, 'Ealdfrost Yak - On Timed Event 1 - Restore Click Flag');
