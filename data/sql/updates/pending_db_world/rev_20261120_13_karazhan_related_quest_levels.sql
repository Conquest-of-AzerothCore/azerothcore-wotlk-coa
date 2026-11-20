-- Keep the original Arcatraz key path, Violet Eye rewards and optional Nightbane summon chain available at 60.
START TRANSACTION;

UPDATE `quest_template`
SET `MinLevel` = 60, `QuestLevel` = 60
WHERE `ID` IN (10205, 10262, 10265, 10266, 10267, 10268, 10269, 10275, 10276, 10280, 10704);

UPDATE `quest_template`
SET `MinLevel` = 60, `QuestLevel` = 60
WHERE `ID` IN (10754, 10755, 10756, 10757, 10758, 10762, 10763, 10764);

UPDATE `quest_template`
SET `MinLevel` = 60, `QuestLevel` = 60
WHERE `ID` IN (9630, 9631, 9637, 9638, 9639, 9640, 9644, 9645, 9680, 9838, 9840, 9843, 9844, 9860,
    10725, 10726, 10727, 10728, 10729, 10730, 10731, 10732, 10733, 10734, 10735, 10736, 10738, 10739,
    10740, 10741, 11216);

UPDATE `dungeon_access_template`
SET `min_level` = 60
WHERE `map_id` IN (553, 554) AND `difficulty` = 0 AND `min_level` > 60;

UPDATE `dungeon_access_template`
SET `min_level` = 60
WHERE `map_id` IN (540, 556) AND `difficulty` = 1 AND `min_level` > 60;

COMMIT;
