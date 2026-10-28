-- The quest tracker text of two Warchief's Command call board quests still named their Cataclysm destinations.
-- It now matches the quest log text and the NPC that ends each quest.
UPDATE `quest_template` SET `QuestCompletionLog` = 'Report to Mitsuwa at Zoram''gar Outpost in Ashenvale.' WHERE `ID` = 14231;
UPDATE `quest_template` SET `QuestCompletionLog` = 'Report to Mebok Mizzyrix at Ratchet in the Barrens.' WHERE `ID` = 14233;
