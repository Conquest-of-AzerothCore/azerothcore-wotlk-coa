-- Quest 33 (a native collect-from-mob quest) has Flags = 3 on the POI of its
-- objective, and 1 only on the turn-in. 23,423 rows use 1 and 1,678 use 3; the
-- difference is the world-space half of the flag, which is what draws the area in
-- the world rather than only on the map.
UPDATE `quest_poi`
SET `Flags` = 3
WHERE `QuestID` IN (17839, 17844) AND `id` IN (0, 1, 2);

UPDATE `quest_poi`
SET `Flags` = 1
WHERE `QuestID` IN (17839, 17844) AND `id` = 3;
