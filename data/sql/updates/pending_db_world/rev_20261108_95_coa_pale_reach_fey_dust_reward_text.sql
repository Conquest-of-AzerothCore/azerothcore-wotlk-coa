-- Fey Dust (175025) reward text, from live footage of Beldred's turn-in window.
DELETE FROM `quest_offer_reward` WHERE `ID` = 175025;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175025, 0, 0, 0, 0, 0, 0, 0, 0, '<Beldred brings her aquiline nose close to the fey dust and breathes in the radiating magic deeply. For a moment, her eyes roll back.>$B$BAh! Good. I am satisfied, yes. This will last me for several months.$B$BLet it not be said that Beldred fails to keep her word! While you were shaking the dust off their dainty little corpses, I went ahead and began brewing the potion.$B$BI just need a moment to finish it.', 0);
