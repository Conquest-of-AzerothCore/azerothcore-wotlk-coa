-- The Ealdir Trial of Strength (175037) had no completion text, so Raigh Anramor's turn-in window was blank. Text from
-- the realm turn-in window (Redthedeer VOD DuWTvw19xtg, 00:42:22).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175037;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175037, 0, 0, 0, 0, 0, 0, 0, 0, 'Impressive! And you''ve only just arrived.$B$BIf every Ealdir fought like you, we would win this war in the blink of an eye.$B$BYou have earned the right to be here. Consider the Ealdmaine Caverns your new home from now on. We have much to do.', 0);
