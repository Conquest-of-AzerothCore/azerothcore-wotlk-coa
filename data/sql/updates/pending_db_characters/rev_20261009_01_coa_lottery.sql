CREATE TABLE IF NOT EXISTS `coa_lottery_round` (
  `id` BIGINT UNSIGNED NOT NULL,
  `active` TINYINT UNSIGNED DEFAULT NULL,
  `ends_at` BIGINT UNSIGNED NOT NULL,
  `pot` INT UNSIGNED NOT NULL DEFAULT 0,
  `seed` INT UNSIGNED NOT NULL DEFAULT 0,
  `contribution_percent` INT UNSIGNED NOT NULL DEFAULT 100,
  `duration_seconds` INT UNSIGNED NOT NULL DEFAULT 604800,
  `winner_guid` INT UNSIGNED DEFAULT NULL,
  `payout_mail_id` INT UNSIGNED DEFAULT NULL,
  `bonus_item` INT UNSIGNED NOT NULL DEFAULT 0,
  `fake_tickets` INT UNSIGNED NOT NULL DEFAULT 0,
  `paused` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `paused_remaining` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `one_active_round` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `coa_lottery_entry` (
  `round_id` BIGINT UNSIGNED NOT NULL,
  `guid` INT UNSIGNED NOT NULL,
  `tickets` INT UNSIGNED NOT NULL,
  `spent_copper` INT UNSIGNED NOT NULL DEFAULT 0,
  `pot_copper` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`round_id`, `guid`),
  KEY `character_entries` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `coa_lottery_winner` (
  `round_id` BIGINT UNSIGNED NOT NULL,
  `drawn_at` BIGINT UNSIGNED NOT NULL,
  `winner_guid` INT UNSIGNED NOT NULL,
  `winner_account_id` INT UNSIGNED NOT NULL,
  `winner_name` VARCHAR(64) NOT NULL,
  `gold_copper` INT UNSIGNED NOT NULL,
  `bonus_item` INT UNSIGNED NOT NULL DEFAULT 0,
  `bonus_item_name` VARCHAR(255) NOT NULL DEFAULT '',
  `winner_tickets` INT UNSIGNED NOT NULL,
  `total_tickets` INT UNSIGNED NOT NULL,
  `payout_mail_id` INT UNSIGNED NOT NULL,
  `house_win` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `destroyed_copper` INT UNSIGNED NOT NULL DEFAULT 0,
  `admin_forced` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `complimentary_tickets` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`round_id`),
  KEY `draw_history` (`drawn_at`, `round_id`),
  KEY `character_history` (`winner_guid`, `round_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `coa_lottery_control` (
  `id` TINYINT UNSIGNED NOT NULL,
  `enabled` TINYINT UNSIGNED DEFAULT NULL,
  `auto_start` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `coa_lottery_control` (`id`, `enabled`, `auto_start`) VALUES (1, NULL, 1);
