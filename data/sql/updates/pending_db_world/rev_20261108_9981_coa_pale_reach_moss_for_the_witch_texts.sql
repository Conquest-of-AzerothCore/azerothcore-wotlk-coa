-- Moss for the Witch (175336): Deirdre's progress and turn-in windows were empty. Transcribed from live footage of
-- the turn-in (https://youtu.be/fppvzzEmIX8?t=1361, 0:22:41-0:22:42).
DELETE FROM `quest_request_items` WHERE `ID` = 175336;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175336, 0, 0, 'What of my moss?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175336;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175336, 0, 0, 0, 0, 0, 0, 0, 0, 'Good. This will suffice.$B$B<Deirdre snaps a finger, and the moss vanishes magically from your hands.>$B$BIt is an enhancer, you know. For our rituals. It lifts the mind above the burdens and ballast of the flesh, all the way to the very roof of the Spirit World.', 0);
