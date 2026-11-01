-- Remove the hidden tracking quests: they were an invention, not native behaviour.
DELETE FROM `creature_queststarter` WHERE `quest` IN (17840, 17845);
DELETE FROM `creature_questender` WHERE `quest` IN (17840, 17845);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (17840, 17845);
DELETE FROM `quest_poi` WHERE `QuestID` IN (17840, 17845);
DELETE FROM `quest_template` WHERE `ID` IN (17840, 17845);
