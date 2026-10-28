-- Coldridge Pass: remove the inferred Statue of Uther and retire the Templar quest that visits it (200083 A Quiet
-- Life): no giver, turn-in or map points.
DELETE FROM `gameobject` WHERE `guid` IN (6912219, 7912219) AND `id` = 9301155;

DELETE FROM `smart_scripts` WHERE `entryorguid` = -9003327 AND `source_type` = 0;
DELETE FROM `creature_addon` WHERE `guid` = 9003327;
DELETE FROM `creature` WHERE `guid` = 9003327 AND `id` = 685037;

DELETE FROM `creature_queststarter` WHERE `quest` = 200083;
DELETE FROM `creature_questender` WHERE `quest` = 200083;
DELETE FROM `quest_poi_points` WHERE `QuestID` = 200083;
DELETE FROM `quest_poi` WHERE `QuestID` = 200083;
