-- Caught! (4449) ends at the Wooden Outhouse in Searing Gorge, as its own description says, but the quest tracker
-- sent players to Badlands (#11259).
UPDATE `quest_template` SET `QuestCompletionLog` = 'Return to Wooden Outhouse in Searing Gorge.' WHERE `ID` = 4449 AND `QuestCompletionLog` = 'Return to Wooden Outhouse in Badlands.';
