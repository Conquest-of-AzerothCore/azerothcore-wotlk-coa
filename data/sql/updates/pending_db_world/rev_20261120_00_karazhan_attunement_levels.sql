UPDATE `quest_template`
SET `MinLevel` = 60, `QuestLevel` = 60
WHERE `ID` IN (9824, 9825, 9826, 9829, 9831, 9832, 9836, 9837, 10277, 10279, 10282, 10283, 10284, 10285, 10737);

UPDATE `dungeon_access_template`
SET `min_level` = 60
WHERE `map_id` IN (269, 532, 552, 555, 560) AND `difficulty` = 0 AND `min_level` > 60;
