-- Scaidern Village (175061): Sir Draewyn's progress and turn-in texts were empty; transcribed from the live realm
-- (video i5vATMYui0I 01:38:46). The emote's closing bracket is missing on the realm as well.
DELETE FROM `quest_request_items` WHERE `ID` = 175061;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175061, 0, 0, 'Word from Scaidern Village, then? Speak.', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175061;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175061, 0, 0, 0, 0, 0, 0, 0, 0, 'Dead.$B$BA pity so many allow themselves to be seduced by such notions. Scadeald would be far stronger if the Ealdir withdrew to the forests and ceased their struggle for secession.$B$B<Sir Draewyn sighs. Then, he nods in a gesture of recognition.$BHere is your reward.', 0);
