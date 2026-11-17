-- Deferred Blessing (175329): Sacristan Tareth's turn-in text was empty; transcribed from the live realm (video
-- RIEMlZSgbQw 06:46:15-06:46:30).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175329;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175329, 0, 0, 0, 0, 0, 0, 0, 0, 'Ah, a locket.$B$B<Tareth smiles kindly.>$B$BIt is not uncommon for such things to find their way to Hallow Wind. Some believe that surrendering a personal possession is enough to spare them the journey themselves.$B$BI will pray for her spirit all the same. And for her mother''s health.', 0);
