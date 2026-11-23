-- Ragefire Chasm: the Blood Filled Orb next to Jergosh summons Zelemar the Wrathful for everybody, as on Ascension
-- (#11770).
-- It was locked to quest 9692 (GO_FLAG_INTERACT_COND and Data1), which nobody here can have.
UPDATE `gameobject_template` SET `Data1` = 0 WHERE `entry` = 182024;
UPDATE `gameobject_template_addon` SET `flags` = `flags` & ~4 WHERE `entry` = 182024;

-- The orb summons him without sending him at the player at once.
UPDATE `smart_scripts` SET `action_param4` = 0
WHERE `entryorguid` = 182024 AND `source_type` = 1 AND `id` = 0 AND `action_type` = 12;

DELETE FROM `creature_text` WHERE `CreatureID` = 17830 AND `GroupID` IN (0, 1) AND `ID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
    `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(17830, 0, 0, 'Who dare summon me!', 14, 0, 100, 0, 0, 0, 0, 0, 'Zelemar the Wrathful - On Summoned'),
(17830, 1, 0, '%s becomes enraged!', 16, 0, 100, 0, 0, 0, 0, 0, 'Zelemar the Wrathful - At 20 % health');

-- He shouts, stays unattackable for three seconds, then attacks the closest player (the one at the orb).
-- Rain of Fire first after 10 s, then every 12 s, on a random target. Enrage at 20 % health.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 17830 AND `source_type` = 0 AND `id` IN (9001, 9002, 9003, 9004, 9005,
    9006, 9007, 9008, 9009, 9010);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
    `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
    `target_y`, `target_z`, `target_o`, `comment`) VALUES
(17830, 0, 9001, 0, 0, 0, 100, 0, 10000, 10000, 12000, 12000, 0, 0, 11, 2102550, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0,
    0, 'Zelemar the Wrathful - Ascension kit - In Combat (first 10 s, then every 12 s) - Rain of Fire on random'),
(17830, 0, 9002, 9003, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Just Summoned - Say Line 0'),
(17830, 0, 9003, 9004, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 18, 258, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Just Summoned - Set Unit Flags Non Attackable and Immune To Players'),
(17830, 0, 9004, 9005, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Just Summoned - Set Reactstate Passive'),
(17830, 0, 9005, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 3000, 3000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Just Summoned - Create Timed Event 1 in 3 s'),
(17830, 0, 9006, 9007, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 19, 258, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Timed Event 1 - Remove Unit Flags Non Attackable and Immune To Players'),
(17830, 0, 9007, 9008, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Timed Event 1 - Set Reactstate Aggressive'),
(17830, 0, 9008, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 21, 30, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - On Timed Event 1 - Attack Closest Player'),
(17830, 0, 9009, 9010, 2, 0, 100, 1, 0, 20, 0, 0, 0, 0, 11, 8599, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - Between 0-20% Health - Cast ''Enrage'' (No Repeat)'),
(17830, 0, 9010, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zelemar the Wrathful - Between 0-20% Health - Say Line 1');

-- His Mythic+ 22 health on Ascension was 3.904 M. With +22's health factor (1.1245 x 5.75 - 0.02 = 6.4459) that is
-- 605,656 on Mythic, and Heroic is Mythic / 1.3 as for the other Ragefire Chasm bosses.
UPDATE `coa_dungeon_health` SET `max_health` = 605656, `evidence` = 'model',
    `source` = 'Ascension Mythic+ 22: 3.904 M / 6.4459; Zelemar the Wrathful'
WHERE `map_id` = 389 AND `difficulty` = 2 AND `creature_entry` = 17830;
UPDATE `coa_dungeon_health` SET `max_health` = 465889, `evidence` = 'model',
    `source` = 'Heroic from Mythic / 1.3; Zelemar the Wrathful'
WHERE `map_id` = 389 AND `difficulty` = 1 AND `creature_entry` = 17830;
