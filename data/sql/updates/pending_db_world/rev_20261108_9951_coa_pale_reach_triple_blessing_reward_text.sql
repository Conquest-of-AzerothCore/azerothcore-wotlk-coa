-- Triple Blessing (175045): Cathal's turn-in text was empty; transcribed from the live realm (video VGzezmaiv8A 21:40).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175045;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175045, 0, 0, 0, 0, 0, 0, 0, 0, 'You say Aisling sent you?$B$B<Cathal sniffs the air, as if he could tell truth from lies by your scent.>$B$BVery well. There is a way to reach the Three Sisters from Graysky, but you''ll need to listen closely:', 0);
