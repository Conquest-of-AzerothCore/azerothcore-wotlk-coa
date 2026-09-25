-- Shared Manastorm physical-cache resolver.
--
-- Architecture:
--   Normal track  -> select by recipient character level.
--   Endgame track -> select by Manastorm depth.
--
-- This table selects WHICH physical cache item is awarded/displayed.
-- Cache CONTENTS remain data-driven loot-table data. Reconstructed caches may
-- route through reference_loot_template, while mod-manastorm-endless
-- personalizes equal-chance gear candidates at open time.
--
-- selector_kind:
--   1 = character level
--   2 = Manastorm depth
--
-- Evidence notes:
--   * 97877-97883 are preserved level-banded physical cache identities.
--   * 1288xxx/1289xxx are preserved TBC physical cache identities.
--   * TBC endgame ranges below follow the recovered/public TBC progression
--     used by this reconstruction. The historical 51-100 vs 51-105 boundary
--     discrepancy is resolved here as 51-105 so Karazhan begins at 106.
--   * The 826+ tail is taken directly from the preserved physical-cache
--     item descriptions: Mythic Hyjal 826-875, Mythic Black Temple 876-925,
--     and Mythic Sunwell Plateau 926 onward.
--   * 97884 remains the generic Potential Rewards UI identity and is NOT a
--     physical-cache fallback.
--   * Missing ranges intentionally fail resolution; do not silently award
--     97884 or guess another cache.
--
-- Applying this migration does not populate cache loot pools. A physical cache
-- may therefore exist and resolve correctly before its contents have been
-- reconstructed.

CREATE TABLE IF NOT EXISTS `manastorm_cache_bracket`
(
    `bracket_id`       INT UNSIGNED NOT NULL,
    `track`            TINYINT UNSIGNED NOT NULL,
    `selector_kind`    TINYINT UNSIGNED NOT NULL,
    `min_value`        INT UNSIGNED NOT NULL,
    `max_value`        INT UNSIGNED NOT NULL,
    `cache_item_entry` INT UNSIGNED NOT NULL,
    `enabled`          TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `comment`          VARCHAR(255) NOT NULL DEFAULT '',

    PRIMARY KEY (`bracket_id`),
    KEY `idx_cache_resolve`
        (`track`, `selector_kind`, `enabled`, `min_value`, `max_value`),
    KEY `idx_cache_item`
        (`cache_item_entry`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

INSERT INTO `manastorm_cache_bracket`
(
    `bracket_id`,
    `track`,
    `selector_kind`,
    `min_value`,
    `max_value`,
    `cache_item_entry`,
    `enabled`,
    `comment`
)
VALUES
    -- Native Normal/leveling track. Physical identities are preserved by
    -- their item names. Level 60 remains its own legacy band.
    (1, 1, 1, 11, 24, 97877, 1, 'LEVEL_BAND: Manastorm Cache (11-24)'),
    (2, 1, 1, 25, 30, 97878, 1, 'LEVEL_BAND: Manastorm Cache (25-30)'),
    (3, 1, 1, 31, 35, 97879, 1, 'LEVEL_BAND: Manastorm Cache (31-35)'),
    (4, 1, 1, 36, 45, 97880, 1, 'LEVEL_BAND: Manastorm Cache (36-45)'),
    (5, 1, 1, 46, 50, 97881, 1, 'LEVEL_BAND: Manastorm Cache (46-50)'),
    (6, 1, 1, 51, 59, 97882, 1, 'LEVEL_BAND: Manastorm Cache (51-59)'),
    (7, 1, 1, 60, 60, 97883, 1, 'LEVEL_BAND: Manastorm Cache (60)'),

    -- Native Endgame/depth track. Public/recovered TBC progression profile.
    (100, 2, 2,   1,  50, 1288050, 1, 'TBC_BRACKET: Normal Dungeons'),
    (101, 2, 2,  51, 105, 1288051, 1, 'TBC_BRACKET: Heroic Dungeons'),
    (102, 2, 2, 106, 135, 1288052, 1, 'TBC_BRACKET: Karazhan'),
    (103, 2, 2, 136, 165, 1288054, 1, 'TBC_BRACKET: Gruul''s Lair'),
    (104, 2, 2, 166, 195, 1288055, 1, 'TBC_BRACKET: Magtheridon''s Lair'),
    (105, 2, 2, 196, 225, 1288056, 1, 'TBC_BRACKET: Heroic Karazhan'),
    (106, 2, 2, 226, 255, 1288058, 1, 'TBC_BRACKET: Heroic Gruul''s Lair'),
    (107, 2, 2, 256, 285, 1288059, 1, 'TBC_BRACKET: Heroic Magtheridon''s Lair'),
    (108, 2, 2, 286, 315, 1289056, 1, 'TBC_BRACKET: Mythic Karazhan'),
    (109, 2, 2, 316, 345, 1289058, 1, 'TBC_BRACKET: Mythic Gruul''s Lair'),
    (110, 2, 2, 346, 375, 1289059, 1, 'TBC_BRACKET: Mythic Magtheridon''s Lair'),
    (111, 2, 2, 376, 405, 1288060, 1, 'TBC_BRACKET: Serpentshrine Cavern'),
    (112, 2, 2, 406, 435, 1288061, 1, 'TBC_BRACKET: Tempest Keep'),
    (113, 2, 2, 436, 465, 1288063, 1, 'TBC_BRACKET: Heroic Serpentshrine Cavern'),
    (114, 2, 2, 466, 495, 1288064, 1, 'TBC_BRACKET: Heroic Tempest Keep'),
    (115, 2, 2, 496, 525, 1289063, 1, 'TBC_BRACKET: Mythic Serpentshrine Cavern'),
    (116, 2, 2, 526, 555, 1289064, 1, 'TBC_BRACKET: Mythic Tempest Keep'),
    (117, 2, 2, 556, 585, 1288065, 1, 'TBC_BRACKET: Zul''Aman'),
    (118, 2, 2, 586, 615, 1288066, 1, 'TBC_BRACKET: Heroic Zul''Aman'),
    (119, 2, 2, 616, 645, 1289066, 1, 'TBC_BRACKET: Mythic Zul''Aman'),
    (120, 2, 2, 646, 675, 1288067, 1, 'TBC_BRACKET: Hyjal Summit'),
    (121, 2, 2, 676, 705, 1288068, 1, 'TBC_BRACKET: Black Temple'),
    (122, 2, 2, 706, 735, 1288070, 1, 'TBC_BRACKET: Heroic Hyjal Summit'),
    (123, 2, 2, 736, 765, 1288071, 1, 'TBC_BRACKET: Heroic Black Temple'),
    (124, 2, 2, 766, 795, 1288072, 1, 'TBC_BRACKET: Sunwell Plateau'),
    (125, 2, 2, 796, 825, 1288074, 1, 'TBC_BRACKET: Heroic Sunwell Plateau'),
    (126, 2, 2, 826, 875, 1289070, 1, 'TBC_BRACKET: Mythic Hyjal Summit'),
    (127, 2, 2, 876, 925, 1289071, 1, 'TBC_BRACKET: Mythic Black Temple'),
    (128, 2, 2, 926, 4294967295, 1289074, 1, 'TBC_BRACKET: Mythic Sunwell Plateau')
ON DUPLICATE KEY UPDATE
    `track` = VALUES(`track`),
    `selector_kind` = VALUES(`selector_kind`),
    `min_value` = VALUES(`min_value`),
    `max_value` = VALUES(`max_value`),
    `cache_item_entry` = VALUES(`cache_item_entry`),
    `enabled` = VALUES(`enabled`),
    `comment` = VALUES(`comment`);

SELECT
    `bracket_id`,
    `track`,
    `selector_kind`,
    `min_value`,
    `max_value`,
    `cache_item_entry`,
    `enabled`,
    `comment`
FROM `manastorm_cache_bracket`
ORDER BY
    `track`,
    `selector_kind`,
    `min_value`,
    `bracket_id`;
