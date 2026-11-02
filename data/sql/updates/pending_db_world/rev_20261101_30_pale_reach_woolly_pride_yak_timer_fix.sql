-- Woolly Pride (175133), #10028 #10122: the Ealdfrost Yak (164420) "Create Timed Event 1" action omitted its
-- max-delay param (action_param3), defaulting it to 0. SmartAIMgr::IsMinMaxValid rejects min(60000) > max(0)
-- and drops the whole action at load, so the timer that restores the yak's SPELLCLICK flag after 60 s never
-- fires: once a yak is fed, it stays permanently unclickable until a worldserver restart.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164420, 165503) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `target_type`, `comment`) VALUES
(164420, 0, 0, 1, 8, 0, 100, 0, 9978001, 0, 0, 0, 33, 164420, 0, 0, 7, 'Ealdfrost Yak - On Fed - Quest Credit Yaks fed (175133)'),
(164420, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 81, 0, 0, 0, 1, 'Ealdfrost Yak - Linked - Remove Click Flag'),
(164420, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 1, 'Ealdfrost Yak - Linked - Create Timed Event 1 (60 s)'),
(164420, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 81, 16777216, 0, 0, 1, 'Ealdfrost Yak - On Timed Event 1 - Restore Click Flag'),
(165503, 0, 0, 1, 8, 0, 100, 0, 9978002, 0, 0, 0, 33, 165503, 0, 0, 7, 'Yak Dung - On Cleaned - Quest Credit Stables cleaned (175133)'),
(165503, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 41, 1000, 60, 0, 1, 'Yak Dung - Linked - Despawn (respawn 60 s)');
