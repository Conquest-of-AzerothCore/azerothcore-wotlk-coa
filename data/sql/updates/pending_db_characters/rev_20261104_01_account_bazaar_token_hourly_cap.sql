-- Hourly limit on earned Bazaar Tokens (975001): per account the start of its current window and the tokens earned in it.
CREATE TABLE IF NOT EXISTS `account_bazaar_token_hourly_cap` (
  `account` int unsigned NOT NULL,
  `window_start` int unsigned NOT NULL DEFAULT 0,
  `earned` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
