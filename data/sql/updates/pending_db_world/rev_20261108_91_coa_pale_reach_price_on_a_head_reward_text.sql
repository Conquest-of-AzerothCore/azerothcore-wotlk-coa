-- The Price on a Head (175038) reward text, from live footage of Randec's turn-in window.
DELETE FROM `quest_offer_reward` WHERE `ID` = 175038;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175038, 0, 0, 0, 0, 0, 0, 0, 0, 'You killed him. Dammit, you actually killed him. I don\'t even know if I would have been able to best him myself.$B$BBut a deal is a deal. And we agreed to split the reward in two.$B$BHere, take this. You\'ve earned the right to collect your share in advance. It\'ll take me a few days just to reach Graysky in this state, I reckon.', 0);
