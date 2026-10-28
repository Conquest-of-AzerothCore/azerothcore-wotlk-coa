CREATE TABLE IF NOT EXISTS `coa_lfg_teleport_suggestion` (
    `dungeon_id` INT UNSIGNED NOT NULL,
    `account_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `position_x` FLOAT NOT NULL,
    `position_y` FLOAT NOT NULL,
    `position_z` FLOAT NOT NULL,
    `orientation` FLOAT NOT NULL,
    `player` VARCHAR(12) NOT NULL,
    `created` DATETIME NOT NULL,
    PRIMARY KEY (`dungeon_id`, `account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
