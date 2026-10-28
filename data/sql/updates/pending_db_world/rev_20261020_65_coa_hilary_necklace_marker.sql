-- Hilary's Necklace map marker (#7502). The Glinting Mud area pin exists but points at
-- objective index 4, which quest 3741 does not have (its only objective is the necklace,
-- index 0), so no marker is shown. Point the area pin at objective 0.
UPDATE `quest_poi` SET `ObjectiveIndex` = 0 WHERE `QuestID` = 3741 AND `id` = 0;
