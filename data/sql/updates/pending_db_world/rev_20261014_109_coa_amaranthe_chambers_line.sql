-- Lady Amaranthe Naemyl speaks when a player takes "The Chambers of Erdaya" from her (the user's screenshot of live).
DELETE FROM `creature_text` WHERE `CreatureID` = 164278 AND `GroupID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164278, 0, 0, 'I myself helped Cauranos weave the protective enchantments of the Chambers of Erdaya. We both understood the danger they held; the dark attention they might attract. If the Blood Elves have risked so much to force their way into them...', 12, 0, 100, 0, 0, 0, 0, 0, 'Lady Amaranthe Naemyl - The Chambers of Erdaya accepted');
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164278;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164278 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164278, 0, 0, 0, 19, 0, 100, 0, 175100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Lady Amaranthe Naemyl - On Quest ''The Chambers of Erdaya'' Accepted - Say Line 0');
