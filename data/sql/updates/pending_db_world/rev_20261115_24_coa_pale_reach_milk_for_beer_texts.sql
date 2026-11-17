-- Milk for Beer (175337): texts read from Redthedeer's dialogue window (RIEMlZSgbQw 8:17:59-8:18:16);
-- each page becomes a paragraph.
DELETE FROM `quest_request_items` WHERE `ID` = 175337;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175337, 1, 0, 'Is that for me?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175337;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175337, 1, 0, 0, 0, 0, 0, 0, 0, 'Yak milk, you say?$B$B<Stonebraid peers into the nearly overflowing bucket.>$B$BFrom Dalignir''s yaks in Nivelarn, aye.$B$BIt is a rare thing to see a dwarf drinking something that is not beer, but I will offer my customers a cup and let them decide whether it is worth buying.', 0);
