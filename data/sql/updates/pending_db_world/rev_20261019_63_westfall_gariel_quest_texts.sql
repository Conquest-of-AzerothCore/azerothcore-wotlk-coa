-- CoA Westfall: Protector Gariel (490) had no progress or reward text for 254042 'Wanted: Lenore the Hoarder' and
-- 254043 'Take It Back', so both windows opened empty. No capture of the original lines exists (the quest cache
-- does not store them); these texts are newly written to match the quests' descriptions.
DELETE FROM `quest_request_items` WHERE `ID` IN (254042, 254043);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(254042, 0, 0, 'Lenore still walks free? Then the caravans are still bleeding. Find her, $N, before she slips away again.', 0),
(254043, 0, 0, 'Any luck at the old tower? Every night we wait, the Defias carry off more of what little we have left.', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (254042, 254043);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(254042, 0, 0, 0, 0, 0, 0, 0, 0, 'Lenore the Hoarder, dead at last. You have no idea how many sleepless nights she has cost this militia.$B$BWith her gone, the Defias lose one of their best suppliers, and our caravans might actually reach the outposts for once. Westfall owes you a debt, $N.', 0),
(254043, 0, 0, 0, 0, 0, 0, 0, 0, 'Food, bandages, tools... this is more than I dared hope for. You went right into their nest and came back with it.$B$BThis will keep the militia on its feet a while longer. The Defias took it from us, and you took it back. Thank you, $N.', 0);
