-- Missing texts at the old watchtower, transcribed from the live realm (video HIbr82QgX6w): Sister Sarah's turn-in text
-- for Shelter in the Watchtower (175055, 01:43:34-01:43:48) and Soldier Rulven's progress and turn-in texts for
-- Kharadol Supplies (175058, 01:53:27-01:53:53).
DELETE FROM `quest_offer_reward` WHERE `ID` IN (175055, 175058);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175055, 0, 0, 0, 0, 0, 0, 0, 0, 'Are you injured as well?$B$B<The priestess scans you with eyes full of compassion. Then, her expression relaxes.>$B$BNo. You must be the one everyone is talking about. The one who has saved so many lives.$B$BI would say ''May the Light bless you,'' but I believe it already has. And through you, it has blessed us all.', 0),
(175058, 0, 0, 0, 0, 0, 0, 0, 0, 'I''ll distribute the weapons and ammunition myself.$B$BSister Sarah will know how to manage the medical supplies better than I. But first, take this: sooner or later, you''ll have need of it. You never stop, do you!$B$BDon''t refuse it; with what you''ve brought back, we could treat the wounded of three wars.', 0);

DELETE FROM `quest_request_items` WHERE `ID` = 175058;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175058, 0, 0, 'The ammunition, weapons, and medicine should be inside the Kharadol Bridge. Have you found it all?', 0);
