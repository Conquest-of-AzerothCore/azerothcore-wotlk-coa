-- Lieutenant Frieren's missing Zuramunda texts, transcribed from the live realm (video HIbr82QgX6w 01:41:13-01:41:41):
-- the turn-in text of Fangs of Zuramunda (175052) and the progress texts of A Troll's Grim Mercy (175053) and War's
-- True Ambition (175054).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175052;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175052, 0, 0, 0, 0, 0, 0, 0, 0, 'Yes. <A cruel smile spreads across the lieutenant''s face.> Their screams could be heard even from here.$B$BIt was about time those bastards learned the meaning of fear.', 0);

DELETE FROM `quest_request_items` WHERE `ID` IN (175053, 175054);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175053, 0, 0, 'The safety of the hostages is our priority.', 0),
(175054, 0, 0, 'You seem uneasy... Do you know something I don''t?', 0);
