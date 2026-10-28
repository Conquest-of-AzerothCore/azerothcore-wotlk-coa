-- The Thane's Inner Circle (175183): the quest asks the player to report to Mountaineer Captain Farignar (164466) at
-- Ada-Gumbad and needs his credit, but nothing gave it, so the quest could never be completed. Talking to him now
-- gives the credit, like the other Pale Reach "report to" quests (Engrym, General Baugwolf).
-- The objective had no text, so the client showed "Mountaineer Captain Farignar slain"; it now reads like theirs.
UPDATE `quest_template` SET `ObjectiveText1` = 'Farignar informed' WHERE `ID` = 175183;
-- The turn-in windows had no text, only the Senator's seal it takes; neither the Ascension caches nor the Pale Reach
-- import hold one, so Farignar's lines are written from the quest and the follow-up he offers.
DELETE FROM `quest_request_items` WHERE `ID` = 175183;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175183, 1, 1, 'That is the seal of Senator Anvilmar. Speak, $c. What news do you bring to Ada-Gumbad?', 0);
DELETE FROM `quest_offer_reward` WHERE `ID` = 175183;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175183, 5, 1, 0, 0, 0, 0, 0, 0, 'The Thane himself? Azaghal Stonesong would march on Ironforge?$B$BIf that is true, Ada-Gumbad stands squarely in his path. You were right to come to me, $N, and the Senator was right to trust you.', 0);
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164466;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164466 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164466, 0, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164466, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Mountaineer Captain Farignar - On Gossip Hello - Quest Credit The Thane\'s Inner Circle (175183)');
