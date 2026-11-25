UPDATE `quest_template` SET `Flags` = `Flags` | 0x100 WHERE `ID` BETWEEN 9417101 AND 9417117;
UPDATE `quest_template` SET `RewardMoneyDifficulty` = 6 WHERE `ID` IN (9417116, 9417117);
