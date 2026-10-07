-- Classic Chapter-2 reward catalogue from supplied item descriptions and official table:
-- https://ascension.gg/de/news/chapter-2-pre-patch-updates/461
-- Cache availability begins at the listed floor. Its previous completed floor
-- is the persistent unlock requirement, scoped to character, party-size mode and track.
-- The completing floor is considered prospectively inside the existing atomic
-- stage-completion transaction; the UI uses committed history only.
-- Apply with the accompanying source change and restart. No character SQL is needed.
-- This switches the active endgame catalogue to Classic, preserving TBC rows as disabled.
-- Level-banded normal-track rewards, cache contents and existing inventory are unchanged.
-- The supplied DBC contains older/different equipment-toast depths. This migration
-- uses agreeing Chapter-2 item ranges and the official cache table, not stale toast depths.

CREATE TABLE IF NOT EXISTS `manastorm_cache_unlock_requirement`
(
    `item_entry` INT UNSIGNED NOT NULL,
    `track` TINYINT UNSIGNED NOT NULL,
    `required_completed_depth` INT UNSIGNED NOT NULL,
    `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`item_entry`, `track`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

START TRANSACTION;

UPDATE `manastorm_cache_bracket` SET `enabled` = 0
WHERE `track` = 2 AND `selector_kind` = 2;

DELETE FROM `manastorm_cache_bracket` WHERE `bracket_id` BETWEEN 1000 AND 1019;
INSERT INTO `manastorm_cache_bracket`
(`bracket_id`, `track`, `selector_kind`, `min_value`, `max_value`, `cache_item_entry`, `enabled`, `comment`)
VALUES
(1000, 2, 2, 1, 24, 1278050, 1, 'Manastorm Cache: Normal Dungeons'),
(1001, 2, 2, 25, 105, 1278051, 1, 'Manastorm Cache: Heroic Dungeons'),
(1002, 2, 2, 106, 145, 1278052, 1, 'Manastorm Cache: Zul''Gurub'),
(1003, 2, 2, 146, 185, 1278053, 1, 'Manastorm Cache: Heroic Zul''Gurub'),
(1004, 2, 2, 186, 220, 1278055, 1, 'Manastorm Cache: Mythic Zul''Gurub'),
(1005, 2, 2, 221, 280, 1278056, 1, 'Manastorm Cache: Molten Core'),
(1006, 2, 2, 281, 340, 1278058, 1, 'Manastorm Cache: Heroic Molten Core'),
(1007, 2, 2, 341, 425, 1278060, 1, 'Manastorm Cache: Mythic Molten Core'),
(1008, 2, 2, 426, 450, 1278066, 1, 'Manastorm Cache: Blackwing Lair'),
(1009, 2, 2, 451, 475, 1278068, 1, 'Manastorm Cache: Heroic Blackwing Lair'),
(1010, 2, 2, 476, 510, 1278069, 1, 'Manastorm Cache: Mythic Blackwing Lair'),
(1011, 2, 2, 511, 535, 1278070, 1, 'Manastorm Cache: Ruins of Ahn''Qiraj'),
(1012, 2, 2, 536, 560, 1278072, 1, 'Manastorm Cache: Heroic Ruins of Ahn''Qiraj'),
(1013, 2, 2, 561, 610, 1278074, 1, 'Manastorm Cache: Mythic Ruins of Ahn''Qiraj'),
(1014, 2, 2, 611, 655, 1278075, 1, 'Manastorm Cache: Temple of Ahn''Qiraj'),
(1015, 2, 2, 656, 700, 1278077, 1, 'Manastorm Cache: Heroic Temple of Ahn''Qiraj'),
(1016, 2, 2, 701, 740, 1278078, 1, 'Manastorm Cache: Mythic Temple of Ahn''Qiraj'),
(1017, 2, 2, 741, 840, 1278079, 1, 'Manastorm Cache: Naxxramas'),
(1018, 2, 2, 841, 945, 1278081, 1, 'Manastorm Cache: Heroic Naxxramas'),
(1019, 2, 2, 946, 4294967295, 1278083, 1, 'Manastorm Cache: Mythic Naxxramas');

DELETE FROM `manastorm_cache_unlock_requirement` WHERE `track` = 2 AND `item_entry` IN ( 1278050, 1278051, 1278052, 1278053, 1278055, 1278056, 1278058, 1278060, 1278066, 1278068, 1278069, 1278070, 1278072, 1278074, 1278075, 1278077, 1278078, 1278079, 1278081, 1278083 );
INSERT INTO `manastorm_cache_unlock_requirement`
(`item_entry`, `track`, `required_completed_depth`, `enabled`)
VALUES
(1278050, 2, 0, 1),
(1278051, 2, 24, 1),
(1278052, 2, 105, 1),
(1278053, 2, 145, 1),
(1278055, 2, 185, 1),
(1278056, 2, 220, 1),
(1278058, 2, 280, 1),
(1278060, 2, 340, 1),
(1278066, 2, 425, 1),
(1278068, 2, 450, 1),
(1278069, 2, 475, 1),
(1278070, 2, 510, 1),
(1278072, 2, 535, 1),
(1278074, 2, 560, 1),
(1278075, 2, 610, 1),
(1278077, 2, 655, 1),
(1278078, 2, 700, 1),
(1278079, 2, 740, 1),
(1278081, 2, 840, 1),
(1278083, 2, 945, 1);

COMMIT;
