CREATE TABLE IF NOT EXISTS `coa_daily_login_rewards` (
    `id` INT UNSIGNED NOT NULL,
    `item_entry` INT UNSIGNED NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
    `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `coa_daily_login_rewards`
WHERE `id` = 1 AND `item_entry` = 975001 AND `quantity` = 200 AND `enabled` = 1;

INSERT IGNORE INTO `coa_daily_login_rewards` (`id`, `item_entry`, `quantity`, `enabled`)
VALUES (1, 975001, 200, 1);
