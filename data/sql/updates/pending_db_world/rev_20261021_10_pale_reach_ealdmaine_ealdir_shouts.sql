-- Ealdmaine Ealdir (164049): every guard shouted "Get back! Have you lost your mind?" at any disguised player within
-- 8 yd, so walking through the caverns in Ealdir Attire set off a chorus. The disguise now passes in silence and
-- the line is kept as an occasional aggro shout.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164049 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164049, 0, 0, 0, 4, 0, 25, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdmaine Ealdir - On Aggro - Say Line 1 (25%)'),
(164049, 0, 100, 0, 0, 0, 100, 0, 3000, 6000, 8000, 12000, 0, 0, 11, 365097, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdmaine Ealdir - In Combat - Cast Strike'),
(164049, 0, 101, 0, 0, 0, 100, 0, 5000, 8000, 15000, 20000, 0, 0, 11, 365096, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdmaine Ealdir - In Combat - Cast Rend'),
(164049, 0, 102, 0, 0, 0, 100, 0, 8000, 12000, 600000, 600000, 0, 0, 11, 365071, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ealdmaine Ealdir - In Combat - Cast Rabies');

DELETE FROM `creature_text` WHERE `CreatureID` = 164049 AND `GroupID` = 0;
