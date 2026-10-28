-- Reconstructed targets from user video readings, not recovered original server formulas.
-- Rounded video labels retain their stated precision. Recount damage totals are excluded.
-- Normal is unchanged. Estimates and video observations are explicitly distinguished.
CREATE TABLE IF NOT EXISTS `coa_dungeon_health` (
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `difficulty` TINYINT UNSIGNED NOT NULL,
    `creature_entry` INT UNSIGNED NOT NULL,
    `max_health` INT UNSIGNED NOT NULL,
    `evidence` VARCHAR(16) NOT NULL,
    `source` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`map_id`, `difficulty`, `creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
DELETE FROM `coa_dungeon_health` WHERE (`map_id`, `difficulty`, `creature_entry`) IN (
    (429, 1, 14386),
    (429, 1, 11448),
    (429, 1, 14389),
    (429, 1, 14323),
    (429, 1, 11450),
    (429, 1, 14325),
    (429, 1, 11445),
    (429, 1, 11501),
    (429, 1, 14324),
    (429, 1, 11441),
    (429, 2, 14326),
    (429, 2, 14322),
    (429, 2, 11441),
    (429, 2, 11444),
    (429, 2, 14321),
    (429, 2, 13160),
    (429, 2, 14323),
    (329, 1, 10390),
    (329, 1, 10391),
    (329, 1, 10381),
    (329, 1, 10382),
    (329, 1, 10405),
    (329, 1, 10411),
    (329, 1, 10408),
    (329, 1, 10414),
    (329, 1, 11082),
    (329, 1, 11058),
    (329, 1, 10558),
    (329, 1, 10808),
    (329, 1, 10419),
    (329, 1, 10418),
    (329, 1, 11032),
    (329, 1, 10385),
    (289, 1, 10508),
    (429, 1, 14321),
    (429, 1, 14322),
    (429, 1, 14326));
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
    (429, 1, 14386, 9373, 'video', 'User video reading 2026-09-26: Wandering Eye'),
    (429, 1, 11448, 46800, 'video', 'User video reading 2026-09-26: Gordok Warlock'),
    (429, 1, 14389, 31300, 'video', 'User video reading 2026-09-26: Netherwalker'),
    (429, 1, 14323, 581500, 'video', 'User video reading 2026-09-26: Guard Slipkik'),
    (429, 1, 11450, 73200, 'video', 'User video reading 2026-09-26: Gordok Reaver'),
    (429, 1, 14325, 581500, 'video', 'User video reading 2026-09-26: Captain Kromcrush'),
    (429, 1, 11445, 96400, 'video', 'User video reading 2026-09-26: Gordok Captain'),
    (429, 1, 11501, 581500, 'video', 'User video reading 2026-09-26: King Gordok'),
    (429, 1, 14324, 90400, 'video', 'User video reading 2026-09-26: Chorush'),
    (429, 1, 11441, 73200, 'video', 'User video reading 2026-09-26: Gordok Brute; HC reread'),
    (429, 2, 14326, 754600, 'video', 'User video reading 2026-09-26: Guard Moldar'),
    (429, 2, 14322, 755100, 'video', 'User video reading 2026-09-26: Stomper Kreeg'),
    (429, 2, 11441, 71400, 'video', 'User video reading 2026-09-26: Gordok Brute; below HC observation; different video data may differ'),
    (429, 2, 11444, 45618, 'video', 'User video reading 2026-09-26: Gordok Mage-Lord'),
    (429, 2, 14321, 756800, 'video', 'User video reading 2026-09-26: Guard Fengus'),
    (429, 2, 13160, 27700, 'video', 'User video reading 2026-09-26: Carrion Swarmer'),
    (429, 2, 14323, 751000, 'video', 'User video reading 2026-09-26: Guard Slipkik; approximate'),
    (329, 1, 10390, 19900, 'video', 'User video reading 2026-09-26: Skeletal Guardian'),
    (329, 1, 10391, 35500, 'video', 'User video reading 2026-09-26: Skeletal Berserker'),
    (329, 1, 10381, 28400, 'video', 'User video reading 2026-09-26: Ravaged Cadaver'),
    (329, 1, 10382, 28400, 'video', 'User video reading 2026-09-26: Mangled Cadaver'),
    (329, 1, 10405, 58500, 'video', 'User video reading 2026-09-26: Plague Ghoul'),
    (329, 1, 10411, 25600, 'video', 'User video reading 2026-09-26: Eye of Naxxramas'),
    (329, 1, 10408, 58500, 'video', 'User video reading 2026-09-26: Rockwing Gargoyle'),
    (329, 1, 10414, 150700, 'video', 'User video reading 2026-09-26: Patchwork Horror'),
    (329, 1, 11082, 316300, 'video', 'User video reading 2026-09-26: Stratholme Courier'),
    (329, 1, 11058, 372100, 'video', 'User video reading 2026-09-26: Fras Siabi'),
    (329, 1, 10558, 488800, 'video', 'User video reading 2026-09-26: Hearthsinger Forresten'),
    (329, 1, 10808, 372100, 'video', 'User video reading 2026-09-26: Timmy the Cruel'),
    (329, 1, 10419, 41000, 'video', 'User video reading 2026-09-26: Crimson Conjuror'),
    (329, 1, 10418, 72300, 'video', 'User video reading 2026-09-26: Crimson Guardsman'),
    (329, 1, 11032, 372100, 'video', 'User video reading 2026-09-26: Malor the Zealous'),
    (329, 1, 10385, 58500, 'video', 'User video reading 2026-09-26: Ghostly Citizen'),
    (289, 1, 10508, 372200, 'video', 'User video reading 2026-09-26: Ras Frostwhisper'),
    (429, 1, 14321, 581500, 'estimate', 'DM guard group inferred from Slipkik HC; individual HC HP unobserved'),
    (429, 1, 14322, 581500, 'estimate', 'DM guard group inferred from Slipkik HC; individual HC HP unobserved'),
    (429, 1, 14326, 581500, 'estimate', 'DM guard group inferred from Slipkik HC; individual HC HP unobserved');

-- CoA client-capture HealthModifier values; preserve class and other combat fields.
-- Uploaded snapshot 1a377c9c0a3592c0c8ed077ea6b0128dab0ebf7c: Slipkik, Reaver, Crimson Conjuror.
UPDATE `creature_template` SET `HealthModifier` = 75 WHERE `entry` = 114323;
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` = 111450;
UPDATE `creature_template` SET `HealthModifier` = 8 WHERE `entry` = 110419;
-- Additional archive values read and supplied by the user in the same investigation.
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` IN (111441, 110385, 110405);
UPDATE `creature_template` SET `HealthModifier` = 8 WHERE `entry` = 111448;
