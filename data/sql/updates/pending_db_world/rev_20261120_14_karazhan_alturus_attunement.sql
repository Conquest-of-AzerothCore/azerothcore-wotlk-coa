INSERT INTO `quest_template`
    (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`,
     `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`,
     `RequiredNpcOrGoCount1`, `RewardItem1`, `RewardAmount1`)
VALUES
    (200837, 2, 60, 60, 2562, 62, 10, 'The Key to Karazhan',
     'Defeat Kel''Thuzad in Naxxramas and return to Archmage Alturus outside Karazhan.',
     'The Violet Eye has need of champions. Defeat Kel''Thuzad in Naxxramas, then return to me and I will entrust you with the key to Karazhan.',
     'Return to Archmage Alturus outside Karazhan.', 15990, 1, 24490, 1)
ON DUPLICATE KEY UPDATE `ID` = `ID`;

DELETE FROM `creature_queststarter` WHERE `id` = 17613 AND `quest` IN (9824, 9825, 9826, 200837);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (17613, 200837);

DELETE FROM `creature_questender` WHERE `id` = 17613 AND `quest` = 200837;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (17613, 200837);
