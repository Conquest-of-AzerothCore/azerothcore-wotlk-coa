-- Deathknell has no Witch Doctor trainer on CoA. Shadow-Walker Voss 9300251 (rev_20260923_09) was made for
-- CoA's letter 53016 "Spirit Fetish" ("Seek out Shadow-Walker Voss in Deathknell"), but CoA filed that letter
-- under quest sort 508 (Reaper), not 523 (Witch Doctor); its Deathknell letter block 53000-53017 has no Witch
-- Doctor letter, CoA's creature cache has no Voss and the Exiles export has no 53016. His spawn, the letter's
-- giver and ender rows and its map marker go; the quest and creature templates stay unreferenced.
DELETE FROM `creature` WHERE `guid` = 9003718 AND `id` = 9300251;
DELETE FROM `creature_queststarter` WHERE `id` = 1569 AND `quest` = 53016;
DELETE FROM `creature_questender` WHERE `id` = 9300251 AND `quest` = 53016;
DELETE FROM `quest_poi_points` WHERE `QuestID` = 53016;
DELETE FROM `quest_poi` WHERE `QuestID` = 53016;
