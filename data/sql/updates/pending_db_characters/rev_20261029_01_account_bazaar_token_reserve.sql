-- Elite Warchest Bazaar Tokens (975001) are Realm Bound: per account the number of warchest tokens it still holds.
-- The reserve is spent first and tokens may only leave the account while it keeps at least this many.
CREATE TABLE IF NOT EXISTS `account_bazaar_token_reserve` (
  `account` int unsigned NOT NULL,
  `reserve` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
