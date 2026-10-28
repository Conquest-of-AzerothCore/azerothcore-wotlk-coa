CREATE TABLE IF NOT EXISTS `ascension_player_ticket` (
    `id` INT UNSIGNED NOT NULL,
    `account` INT UNSIGNED NOT NULL,
    `creator_guid` INT UNSIGNED NOT NULL,
    `creator` VARCHAR(12) NOT NULL,
    `title` VARCHAR(128) NOT NULL,
    `category` TINYINT UNSIGNED NOT NULL,
    `priority` TINYINT UNSIGNED NOT NULL,
    `affected_character` VARCHAR(32) NOT NULL,
    `status` TINYINT UNSIGNED NOT NULL,
    `assigned_to` VARCHAR(12) NOT NULL DEFAULT '',
    `closed_by_creator` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `created` INT UNSIGNED NOT NULL,
    `closed` INT UNSIGNED NOT NULL DEFAULT 0,
    `locale` VARCHAR(4) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_account` (`account`, `closed_by_creator`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `ascension_player_ticket_message` (
    `ticket` INT UNSIGNED NOT NULL,
    `id` INT UNSIGNED NOT NULL,
    `from_gm` TINYINT UNSIGNED NOT NULL,
    `gm_only` TINYINT UNSIGNED NOT NULL,
    `sender` VARCHAR(12) NOT NULL,
    `message` TEXT NOT NULL,
    `created` INT UNSIGNED NOT NULL,
    `read_by` VARCHAR(12) NOT NULL DEFAULT '',
    `read_at` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`ticket`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
