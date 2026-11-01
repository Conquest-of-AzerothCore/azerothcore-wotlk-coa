--
-- #10409: Horde Supplies GO (2300709, quest 175150 "Horde Intervention") is a pure native GOOBER
-- with no SmartAI, autoCloseTime (Data3) = 0 and consumable (Data5, unused by the GOOBER case in
-- GameObject::Use()) = 0. Nothing throttles or disables it after use, so a single crate can be
-- spam-clicked for the whole 7x quest credit. Give it SmartGameObjectAI with an On Use force-despawn,
-- mirroring the sibling "Trogg Idol" (2300633) destroy-once-then-respawn pattern used elsewhere in
-- this same quest batch.
--
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300709;

DELETE FROM `smart_scripts` WHERE (`entryorguid`,`source_type`) IN ((2300709,1));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300709, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 41, 1000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Horde Supplies - On Use - Destroyed, respawns per spawn timer');
