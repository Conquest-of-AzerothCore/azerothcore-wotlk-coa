-- Tracks the one-time welcome warchest mail sent per account (item 2977351)
CREATE TABLE IF NOT EXISTS `coa_account_warchest` (
  `account` INT UNSIGNED NOT NULL,
  `claimed_at` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`account`)
);