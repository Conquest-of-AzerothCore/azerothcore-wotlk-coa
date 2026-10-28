CREATE TABLE IF NOT EXISTS `account_friend` (
  `account` int unsigned NOT NULL,
  `friend_account` int unsigned NOT NULL,
  `original_guid` int unsigned NOT NULL,
  `original_name` varchar(48) NOT NULL,
  `note` varchar(48) NOT NULL DEFAULT '',
  PRIMARY KEY (`account`, `friend_account`),
  KEY `friend_account` (`friend_account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `account_friend_migration` (
  `account` int unsigned NOT NULL,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
