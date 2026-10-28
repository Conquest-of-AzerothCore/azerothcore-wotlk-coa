-- Blood and Duty (175049): the Wounded Graysky Soldiers (164055, 164056) are spawned with curhealth 1, but the core
-- only uses a spawn's curhealth for creatures that do not regenerate health, so they stood at full health and the Roll
-- of Thick Bandage (First Aid 365018, a healing channel) had nothing to heal. They no longer regenerate, so they start
-- wounded; 30 s after a bandage gives credit a soldier falls back to 5% health for the next player, as he never dies
-- and so never respawns.
UPDATE `creature_template` SET `RegenHealth` = 0 WHERE `entry` IN (164055, 164056);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164055, 164056) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164055, 0, 0, 1, 8, 0, 100, 0, 365018, 0, 30000, 30000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Spellhit Roll of Thick Bandage - Say Line 0'),
(164055, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164055, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Link - Quest Credit Wounded soldiers tended'),
(164055, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Link - Create Timed Event 1 in 30 s'),
(164055, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 142, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Timed Event 1 - Set Health 5%'),
(164056, 0, 0, 1, 8, 0, 100, 0, 365018, 0, 30000, 30000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Spellhit Roll of Thick Bandage - Say Line 0'),
(164056, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164055, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Link - Quest Credit Wounded soldiers tended'),
(164056, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Link - Create Timed Event 1 in 30 s'),
(164056, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 142, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Timed Event 1 - Set Health 5%');
