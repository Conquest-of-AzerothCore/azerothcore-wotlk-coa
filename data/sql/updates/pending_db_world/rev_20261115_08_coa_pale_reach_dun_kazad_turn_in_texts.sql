-- No One to Bring Her Flowers (175340) and Hands That Heal (175341): texts read from Redthedeer's dialogue window
-- (RIEMlZSgbQw 9:54:13-9:54:20 and 9:55:28-9:55:44); each page becomes a paragraph.
DELETE FROM `quest_request_items` WHERE `ID` = 175341;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175341, 1, 0, 'Have you brought the flowers?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (175340, 175341);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175340, 0, 0, 0, 0, 0, 0, 0, 0, 'Thank you.$B$B<It is the only thing he says before closing his eyes. To sleep, perhaps. Or to hold back tears.>', 0),
(175341, 1, 0, 0, 0, 0, 0, 0, 0, 'Yes, this will suffice. And in the short term, at least, it will do more good than my prayers, however well-intentioned they may be.$B$BThank you, $C.', 0);
