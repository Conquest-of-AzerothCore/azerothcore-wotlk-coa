-- #12914: Chief Engineer Hinderweir VII never spoke his 'The Stonewrought Dam has been saved!' line (creature_text
-- 1093 group 0, broadcast 546); yell it to the player who turns in 'A Dark Threat Looms' (283)
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 1093;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1093 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `action_type`, `action_param1`, `target_type`, `comment`) VALUES
(1093, 0, 0, 0, 20, 0, 100, 0, 283, 1, 0, 7, 'Chief Engineer Hinderweir VII - On Quest ''A Dark Threat Looms'' Finished - Say Line 0');
