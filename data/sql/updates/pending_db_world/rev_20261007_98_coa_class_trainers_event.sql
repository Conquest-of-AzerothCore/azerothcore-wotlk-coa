-- Conquest of Azeroth class trainers stand only on a CoA realm (CoA.ClassModel = coa): the worldserver starts this
-- internal event there at startup. Mathrengyl Bearwalker stays on every realm: he is also Darnassus's druid
-- trainer and gives stock druid quests.
SET @EVENT := 195;
DELETE FROM `game_event` WHERE `eventEntry` = @EVENT;
INSERT INTO `game_event` (`eventEntry`, `description`, `world_event`, `announce`) VALUES
(@EVENT, 'Conquest of Azeroth - Class Trainers', 5, 0);
DELETE FROM `game_event_creature` WHERE `eventEntry` = @EVENT;
INSERT INTO `game_event_creature` (`eventEntry`, `guid`)
SELECT DISTINCT @EVENT, c.`guid`
FROM `creature` c
JOIN `creature_default_trainer` d ON d.`CreatureId` = c.`id`
JOIN `trainer` t ON t.`Id` = d.`TrainerId`
WHERE t.`Type` = 0 AND t.`Requirement` BETWEEN 12 AND 32 AND c.`id` <> 4217;
