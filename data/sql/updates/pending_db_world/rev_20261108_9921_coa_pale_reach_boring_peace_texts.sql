-- Boring Peace (175343) progress and reward texts, from live footage of Alcarian's turn-in windows
-- (i5vATMYui0I at 1:39:05).
DELETE FROM `quest_request_items` WHERE `ID` = 175343;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175343, 0, 0, 'Yes? Can I help you with something?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175343;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175343, 0, 0, 0, 0, 0, 0, 0, 0, 'Ah, a letter from my brother Vaelor.$B$BWill he ever stop insisting? I doubt it. As stubborn now as he was when we were children.$B$BYou see, he wants me to move to Namarien. The Sanctuary. To follow his example, and that of many other high elves.$B$BBut, if I am honest with you... I am quite comfortable here in Graysky. All that peace would bore me, I think.$B$BI will write him a letter saying as much.', 0);
