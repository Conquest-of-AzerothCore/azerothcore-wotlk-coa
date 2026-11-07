CREATE TABLE IF NOT EXISTS `account_coa_daily_login` (
    `account_id` INT UNSIGNED NOT NULL,
    `last_claim_at` BIGINT UNSIGNED NOT NULL,
    `next_claim_at` BIGINT UNSIGNED NOT NULL,
    `claim_number` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`account_id`),
    CONSTRAINT `chk_coa_daily_login_claim` CHECK (`claim_number` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
