-- Each hide is its own item objective: RequiredItemId1 -> index 4, 2 -> 5, 3 -> 6.
-- Sharing one index (as I did) means the client cannot hide the area of a finished
-- objective, and every area disappears only when the first one completes.
UPDATE `quest_poi` SET `ObjectiveIndex` = 4 WHERE `QuestID` IN (17839, 17844) AND `id` = 0; -- Nytharos
UPDATE `quest_poi` SET `ObjectiveIndex` = 5 WHERE `QuestID` IN (17839, 17844) AND `id` = 1; -- Stormfang
UPDATE `quest_poi` SET `ObjectiveIndex` = 6 WHERE `QuestID` IN (17839, 17844) AND `id` = 2; -- Vaelthara
UPDATE `quest_poi` SET `ObjectiveIndex` = -1 WHERE `QuestID` IN (17839, 17844) AND `id` = 3;
