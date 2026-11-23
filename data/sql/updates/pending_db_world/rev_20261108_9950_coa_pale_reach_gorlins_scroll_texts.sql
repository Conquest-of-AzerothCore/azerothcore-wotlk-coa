-- Gorlin's Scroll (175338): Ergrain Tattersail's progress and turn-in texts as on the live realm (video RIEMlZSgbQw
-- 09:13:31-09:13:57). The scroll icon shows on the last progress line, so the split falls after "Did he?".
DELETE FROM `quest_request_items` WHERE `ID` = 175338;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175338, 0, 0, 'That scroll...$B$B<Ergrain inspects it with a quick glance.>$B$BDo not tell me that idle Gorlin sent you. Did he?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175338;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175338, 0, 0, 0, 0, 0, 0, 0, 0, 'Of all the nerve!$B$BHe disappears for weeks, gives himself over to drink, and then sends me an apology like a coward, through a messenger, and in writing.$B$BAh, Gorlin.$B$B<Ergrain''s eyes burn like two furnaces, but her anger soon spends itself, leaving only embers behind.>$B$B<She smiles at you.>$B$BThank you, I suppose. You are hardly to blame, needless to say.', 0);
