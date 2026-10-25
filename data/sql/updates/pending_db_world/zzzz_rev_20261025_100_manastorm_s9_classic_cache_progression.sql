-- Selected S9 Classic progression as the S10 reconstruction baseline; exact original S10 ranges are unverified.
-- https://kami-labs.fr/en/ascension/guides-ascension/guide-du-debutant-pour-le-manastorm-en/
-- Shared guide boundaries belong to the earlier tier; unlocks require the preceding completed depth.
-- The zzzz prefix sorts after historical module seeds/snapshots in the supported filename-ordered updater.
-- Preserve normal-track routing, disabled TBC data, cache loot, existing inventory and weekly allowance state.
START TRANSACTION;

UPDATE `manastorm_cache_bracket` SET `enabled` = 0 WHERE `track` = 2 AND `selector_kind` = 2;
DELETE FROM `manastorm_cache_bracket` WHERE `bracket_id` BETWEEN 1000 AND 1027;
INSERT INTO `manastorm_cache_bracket`
(`bracket_id`, `track`, `selector_kind`, `min_value`, `max_value`, `cache_item_entry`, `enabled`, `comment`)
VALUES
(1000, 2, 2, 1, 50, 1278050, 1, 'S9-based S10: Normal Dungeons'),
(1001, 2, 2, 51, 100, 1278051, 1, 'S9-based S10: Heroic Dungeons'),
(1002, 2, 2, 101, 150, 1278052, 1, 'S9-based S10: Zul''Gurub'),
(1003, 2, 2, 151, 200, 1278053, 1, 'S9-based S10: Heroic Zul''Gurub'),
(1004, 2, 2, 201, 300, 1278054, 1, 'S9-based S10: Mythic Dungeons'),
(1005, 2, 2, 301, 350, 1278055, 1, 'S9-based S10: Mythic Zul''Gurub'),
(1006, 2, 2, 351, 450, 1278056, 1, 'S9-based S10: Molten Core'),
(1007, 2, 2, 451, 500, 1278058, 1, 'S9-based S10: Heroic Molten Core'),
(1008, 2, 2, 501, 550, 1278059, 1, 'S9-based S10: Mythic+ 1–10'),
(1009, 2, 2, 551, 600, 1278060, 1, 'S9-based S10: Mythic Molten Core'),
(1010, 2, 2, 601, 700, 1278061, 1, 'S9-based S10: Onyxia & Molten Core'),
(1011, 2, 2, 701, 750, 1278063, 1, 'S9-based S10: Heroic Onyxia & Molten Core'),
(1012, 2, 2, 751, 800, 1278064, 1, 'S9-based S10: Mythic+ 11–20'),
(1013, 2, 2, 801, 900, 1278065, 1, 'S9-based S10: Mythic Onyxia & Molten Core'),
(1014, 2, 2, 901, 1000, 1278066, 1, 'S9-based S10: Blackwing Lair'),
(1015, 2, 2, 1001, 1050, 1278068, 1, 'S9-based S10: Heroic Blackwing Lair'),
(1016, 2, 2, 1051, 1150, 1278069, 1, 'S9-based S10: Mythic Blackwing Lair'),
(1017, 2, 2, 1151, 1250, 1278070, 1, 'S9-based S10: Ruins of Ahn''Qiraj (AQ20)'),
(1018, 2, 2, 1251, 1300, 1278072, 1, 'S9-based S10: Heroic Ruins of Ahn''Qiraj'),
(1019, 2, 2, 1301, 1350, 1278073, 1, 'S9-based S10: Mythic+ 21–30'),
(1020, 2, 2, 1351, 1450, 1278074, 1, 'S9-based S10: Mythic Ruins of Ahn''Qiraj'),
(1021, 2, 2, 1451, 1550, 1278075, 1, 'S9-based S10: Temple of Ahn''Qiraj (AQ40)'),
(1022, 2, 2, 1551, 1600, 1278077, 1, 'S9-based S10: Heroic Temple of Ahn''Qiraj'),
(1023, 2, 2, 1601, 1700, 1278078, 1, 'S9-based S10: Mythic Temple of Ahn''Qiraj'),
(1024, 2, 2, 1701, 1800, 1278079, 1, 'S9-based S10: Naxxramas'),
(1025, 2, 2, 1801, 1850, 1278081, 1, 'S9-based S10: Heroic Naxxramas'),
(1026, 2, 2, 1851, 1900, 1278082, 1, 'S9-based S10: Mythic+ 31–40'),
(1027, 2, 2, 1901, 4294967295, 1278083, 1, 'S9-based S10: Mythic Naxxramas');

DELETE FROM `manastorm_cache_unlock_requirement` WHERE `track` = 2 AND `item_entry` IN (1278050, 1278051, 1278052, 1278053, 1278054, 1278055, 1278056, 1278058, 1278059, 1278060, 1278061, 1278063, 1278064, 1278065, 1278066, 1278068, 1278069, 1278070, 1278072, 1278073, 1278074, 1278075, 1278077, 1278078, 1278079, 1278081, 1278082, 1278083);
INSERT INTO `manastorm_cache_unlock_requirement` (`item_entry`, `track`, `required_completed_depth`, `enabled`)
VALUES
(1278050, 2, 0, 1),
(1278051, 2, 50, 1),
(1278052, 2, 100, 1),
(1278053, 2, 150, 1),
(1278054, 2, 200, 1),
(1278055, 2, 300, 1),
(1278056, 2, 350, 1),
(1278058, 2, 450, 1),
(1278059, 2, 500, 1),
(1278060, 2, 550, 1),
(1278061, 2, 600, 1),
(1278063, 2, 700, 1),
(1278064, 2, 750, 1),
(1278065, 2, 800, 1),
(1278066, 2, 900, 1),
(1278068, 2, 1000, 1),
(1278069, 2, 1050, 1),
(1278070, 2, 1150, 1),
(1278072, 2, 1250, 1),
(1278073, 2, 1300, 1),
(1278074, 2, 1350, 1),
(1278075, 2, 1450, 1),
(1278077, 2, 1550, 1),
(1278078, 2, 1600, 1),
(1278079, 2, 1700, 1),
(1278081, 2, 1800, 1),
(1278082, 2, 1850, 1),
(1278083, 2, 1900, 1);

COMMIT;
