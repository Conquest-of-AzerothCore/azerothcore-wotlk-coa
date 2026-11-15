-- Sins Beyond Mercy (175200): Confessor Mourn's progress and turn-in texts were empty. The quest was never seen in live
-- footage; these are the realm's English texts as carried by the AscensionES translation addon (HideXs/AscensionES,
-- data/Quests.lua, Q[175200] pEN and cEN), whose English matches footage for the neighbouring quests.
DELETE FROM `quest_request_items` WHERE `ID` = 175200;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175200, 0, 0, 'Anything to confess?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175200;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175200, 0, 0, 0, 0, 0, 0, 0, 0, 'The will of the Light has been fulfilled.$B$BRepentance, when sincere, does not comfort... it wounds. And what wounds, redeems.$B$BTell me: do you repent of anything?', 0);
