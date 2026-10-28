-- Stratholme: the undead Balnazzar raises on death run at the group.
--
-- Balnazzar summons 25 Skeletal Guardians and Berserkers in the halls of the Scarlet Bastion
-- (creature_summon_groups 10813/1). They only stood where they were summoned, spread over the
-- hallways; now each one attacks the closest player within 150 yards as soon as it appears, so
-- they come into the Crimson Throne room. Event 54 fires for summons only, so the placed
-- skeletons elsewhere in Stratholme are unchanged.

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (10390, 10391) AND `source_type` = 0 AND `id` = 20;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10390, 0, 20, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 150, 0, 0, 0, 0, 0, 0, 0, 'Skeletal Guardian - On Just Summoned - Attack Closest Player (Balnazzar''s undead)'),
(10391, 0, 20, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 150, 0, 0, 0, 0, 0, 0, 0, 'Skeletal Berserker - On Just Summoned - Attack Closest Player (Balnazzar''s undead)');
