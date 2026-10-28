CREATE TABLE IF NOT EXISTS `character_appearance_outfit` (
    `guid` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `appearances` TEXT NOT NULL,
    PRIMARY KEY (`guid`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
