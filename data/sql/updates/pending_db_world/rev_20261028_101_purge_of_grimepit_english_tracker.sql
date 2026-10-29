-- The Purge of Grimepit (175015): the quest tracker's turn-in line was Spanish ("Informa a Padre Amrod")
UPDATE `quest_template` SET `QuestCompletionLog` = 'Report to Father Amrod' WHERE `ID` = 175015;
