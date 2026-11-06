-- Militia Recruit (255339, Westfall "Militia Training"): after a spar it evaded at 1% health and offered the spar
-- again, so the same recruit could be beaten in one hit for every credit. Restore its health when it evades.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 255339 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(255339, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 42, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Reset - Set Invincibility Hp Level 1'),
(255339, 0, 1, 2, 2, 0, 100, 0, 0, 1, 1000, 1000, 0, 0, 33, 255339, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - Between 0-1% Health - Quest Credit ''Militia Training'''),
(255339, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Evade'),
(255339, 0, 3, 4, 62, 0, 100, 0, 58274, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Gossip Option 0 Selected - Close Gossip'),
(255339, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Remove Npc Flag Gossip'),
(255339, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Set Faction 7'),
(255339, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Start Attacking'),
(255339, 0, 7, 8, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Evade - Restore Faction'),
(255339, 0, 8, 9, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Add Npc Flag Gossip'),
(255339, 0, 9, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Set Health 100%');
