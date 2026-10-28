-- Morriga Hollowhoof's words when Death and Justice 1660033 is turned in, as players recorded them on CoA: her thanks
-- at once, and a few moments later her warning about the lake.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161818;

DELETE FROM `creature_text` WHERE `CreatureID` = 161818 AND `GroupID` IN (0, 1);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`) VALUES
(161818, 0, 0, 'Seldom do I voice my gratitude. Take it for the honor it is: to depart without bending the knee before the new tyrant of Three Totems.', 12, 100, 'Morriga - Death and Justice rewarded (CoA)'),
(161818, 1, 0, 'Next time you set foot in the village, you''ll see the lake stained red with the blood of those who stood in my way.', 12, 100, 'Morriga - after Death and Justice (CoA)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161818 AND `source_type` = 0 AND `id` IN (0, 1, 2);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`,
    `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`,
    `target_o`, `comment`) VALUES
(161818, 0, 0, 1, 20, 0, 100, 0, 1660033, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Morriga Hollowhoof - On Death and Justice Rewarded - Say Line 0'),
(161818, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 6000, 6000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Morriga Hollowhoof - Linked - Create Timed Event 1 in 6 s'),
(161818, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Morriga Hollowhoof - On Timed Event 1 - Say Line 1');
