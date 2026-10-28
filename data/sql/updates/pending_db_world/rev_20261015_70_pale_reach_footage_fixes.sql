-- Pale Reach additions from the Roman Murashov live footage (playlist PLMeDZ00QsunU, 2026-08-01..2026-09-05).

-- Tokens of Sacrifice turn-in text at Edrik (F4ZLp4Ihz4o at 8:16).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175050;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175050, 0, 0, 0, 0, 0, 0, 0, 0, '<The chains from which the insignias hang jingle as they pass from your hands to Edrik''s.>$B$BYou''ve managed to recover a fair few.$B$B<Edrik presses the insignias against his breastplate, right over his heart.>$B$BThis is worth more than you know.', 0);

-- Progress texts of Shadowed Ore at Beldred (X4q-gj8abxs at 0:30) and Gentle Herd at the Creepy Cow (U9OM4ZKDXb4 at 1:10).
DELETE FROM `quest_request_items` WHERE `ID` IN (175347, 175350);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175347, 0, 0, 'What have you brought me?', 0),
(175350, 0, 0, 'Moooo?', 0);

-- The Freed Hostage speaks when War's True Ambition is accepted (FK174XOtIbA at 1:52).
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164065;

DELETE FROM `creature_text` WHERE `CreatureID` = 164065;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164065, 0, 0, 'Agramor hides in the deepest reaches of the cave. Cut off his head once you''ve finished him. The higher-ups will need evidence before we drag the Horde into this. An accusation like that... it changes everything.', 12, 0, 100, 0, 0, 0, 0, 0, 'Freed Hostage');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164065 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `action_type`, `action_param1`, `target_type`, `comment`) VALUES
(164065, 0, 0, 0, 19, 0, 100, 0, 175054, 1, 0, 7, 'Freed Hostage - On War''s True Ambition accepted - Say line 0');

-- Lord Servin Darengar rises from his chair for "Lady Serenya's pride will be our undoing" and sits again before
-- Lord Bruck answers (0MqPfOJqF8w at 8:03-8:05; the 2 s standing time is read from frames 2 s apart).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 16400100 AND `source_type` = 9 AND `id` >= 5;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `target_type`, `target_param1`, `target_param2`, `comment`) VALUES
(16400100, 9, 5, 0, 0, 0, 100, 0, 7000, 7000, 91, 5, 1, 0, 0, 'Lord Servin Darengar - Council - Stand up'),
(16400100, 9, 6, 0, 0, 0, 100, 0, 0, 0, 1, 2, 1, 0, 0, 'Lord Servin Darengar - Council - Say line 2'),
(16400100, 9, 7, 0, 0, 0, 100, 0, 2000, 2000, 90, 5, 1, 0, 0, 'Lord Servin Darengar - Council - Sit back down'),
(16400100, 9, 8, 0, 0, 0, 100, 0, 4000, 4000, 1, 2, 19, 164211, 30, 'Lord Servin Darengar - Council - Lord Aldous Bruck line 2'),
(16400100, 9, 9, 0, 0, 0, 100, 0, 3000, 3000, 33, 164500, 18, 40, 0, 'Lord Servin Darengar - Council - Listen to the nobles'' meeting credit');

-- Lady Serenya Coldmere receives the player seated in her armchair (EonfnwnT7Bo at 0:36-0:52).
DELETE FROM `creature_addon` WHERE `guid` = 9960245;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960245, 0, 0, 5, 1, 0, 0, '');

-- Friendly NPCs show their fixed level on live, while hostile creatures scale with the player.
-- EonfnwnT7Bo, F4ZLp4Ihz4o, 0MqPfOJqF8w, 60CpbUas-Ew and ryfZ4CU0ZUc.
UPDATE `creature_template` SET `minlevel` = 34, `maxlevel` = 34 WHERE `entry` IN (164592, 164211);
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 164943;
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 24 WHERE `entry` = 164184;
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 23 WHERE `entry` = 164564;
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 22 WHERE `entry` = 164177;
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22 WHERE `entry` = 164056;
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21 WHERE `entry` IN (164082, 164072, 164596, 164595, 164174);
UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 35 WHERE `entry` = 164190;
UPDATE `creature_template` SET `minlevel` = 16, `maxlevel` = 16 WHERE `entry` IN (164981, 164983);
