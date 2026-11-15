-- Defias Trainee (537) holds position and casts Fireball only within 25 yd; a victim past that was neither
-- chased nor cast at. Same event shape as Gordunni Ogre Mage (5237) ids 6-7: chase out of range, hold again close.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 537 AND `source_type` = 0 AND `id` IN (7, 8);
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(537, 0, 7, 0, 9, 1, 100, 512, 0, 0, 1200, 1200, 26, 100, 21, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Phase 1: victim within 26-100 yd - Allow combat movement (close to casting range)'),
(537, 0, 8, 0, 9, 1, 100, 512, 0, 0, 1200, 1200, 0, 20, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Trainee - Phase 1: victim within 20 yd - Hold position');
