CREATE TABLE IF NOT EXISTS `account_appearance_collection` (
    `account_id` INT UNSIGNED NOT NULL,
    `appearance_id` INT UNSIGNED NOT NULL,
    `source_item` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account_id`, `appearance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_appearance` (
    `guid` INT UNSIGNED NOT NULL,
    `category_id` TINYINT UNSIGNED NOT NULL,
    `appearance_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`guid`, `category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_appearance_settings` (
    `guid` INT UNSIGNED NOT NULL,
    `can_see_item` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `can_see_spell` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `account_vanity_collection` (
    `account_id` INT UNSIGNED NOT NULL,
    `item_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`account_id`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
