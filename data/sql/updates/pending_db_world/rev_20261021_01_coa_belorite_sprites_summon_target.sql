-- Belorite Sprites (#8364): the summoned Belorite Sprite never received its picker as a
-- target. With attackInvoker = 1 the summon calls AttackStart on the bush itself, which is
-- not a unit, so the sprite spawned victimless: no chase, and its victim-targeted cast never
-- fired. attackInvoker = 2 is the proper picker-targeting form, so the sprite engages, chases
-- and casts like any other mob. Keeps the one-spawn-per-bush gate from rev_20261021_00.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300686 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300686, 1, 0, 0, 64, 0, 100, 1, 0, 0, 0, 0, 0, 0, 12, 164306, 4, 60000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Belorita - On Use - Summon Belorite Sprite (attacks the picker)');
