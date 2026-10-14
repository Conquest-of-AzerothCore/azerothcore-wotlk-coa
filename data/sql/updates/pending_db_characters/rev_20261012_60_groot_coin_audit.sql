-- Groot Coin audit records. These tables are append-only history: nothing here is ever dropped or rewritten, so
-- replaying this file keeps every award and exchange, and no foreign key removes history with a deleted character.

-- One row per delivered award. Two unique keys guard against duplicates: an account is paid once per issue, and
-- each external request (`source`, `source_ref`) is paid once. In-game awards use source 'gm' with a NULL
-- `source_ref`, which the unique key does not compare, and awards from the queue have no issue number.
CREATE TABLE IF NOT EXISTS `grootcoin_award` (
  `award_id` CHAR(36) NOT NULL,
  `issue_number` INT UNSIGNED NULL,
  `source` VARCHAR(32) NOT NULL DEFAULT 'gm',
  `source_ref` VARCHAR(64) NULL,
  `recipient_account_id` INT UNSIGNED NOT NULL,
  `recipient_character_guid` INT UNSIGNED NOT NULL,
  `actor_account_id` INT UNSIGNED NOT NULL,
  `actor_character_guid` INT UNSIGNED NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `attribution_ref` VARCHAR(128) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`award_id`),
  UNIQUE KEY `one_award_per_issue_and_account` (`issue_number`, `recipient_account_id`),
  UNIQUE KEY `one_award_per_source_ref` (`source`, `source_ref`),
  KEY `recipient_character_history` (`recipient_character_guid`, `created_at`),
  KEY `recipient_account_history` (`recipient_account_id`, `created_at`),
  KEY `actor_account_history` (`actor_account_id`, `created_at`),
  KEY `created` (`created_at`),
  CONSTRAINT `grootcoin_award_amount` CHECK (`amount` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- The mail and coin stack that carried an award, written in the award's own transaction.
CREATE TABLE IF NOT EXISTS `grootcoin_award_mail` (
  `award_id` CHAR(36) NOT NULL,
  `mail_id` INT UNSIGNED NOT NULL,
  `coin_item_guid` INT UNSIGNED NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`award_id`, `mail_id`, `coin_item_guid`),
  KEY `mail` (`mail_id`),
  KEY `coin_item` (`coin_item_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- One row per exchange, written in the same transaction as the player's inventory save, with the rate that applied.
CREATE TABLE IF NOT EXISTS `grootcoin_exchange` (
  `exchange_id` CHAR(36) NOT NULL,
  `account_id` INT UNSIGNED NOT NULL,
  `character_guid` INT UNSIGNED NOT NULL,
  `coin_entry` INT UNSIGNED NOT NULL,
  `token_entry` INT UNSIGNED NOT NULL,
  `coins_spent` INT UNSIGNED NOT NULL,
  `tokens_delivered` INT UNSIGNED NOT NULL,
  `tokens_per_coin` INT UNSIGNED NOT NULL,
  `source` VARCHAR(32) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`exchange_id`),
  KEY `account_history` (`account_id`, `created_at`),
  KEY `character_history` (`character_guid`, `created_at`),
  KEY `created` (`created_at`),
  CONSTRAINT `grootcoin_exchange_payout` CHECK (`coins_spent` > 0 AND `tokens_delivered` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Awards requested from outside the game (a website, a bot). The requester inserts a 'pending' row; with
-- GrootCoin.ExternalAwardsEnable = 1 the worldserver pays it through the same checks, audit and mail as
-- `.groot award`, then sets 'done' with the award id (in the award's own transaction) or 'failed' with a reason.
-- (`source`, `source_ref`) is the requester's idempotency key: inserting the same request twice fails.
CREATE TABLE IF NOT EXISTS `groot_coin_award_queue` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `source` VARCHAR(32) NOT NULL,
  `source_ref` VARCHAR(64) NOT NULL,
  `character_guid` INT UNSIGNED NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `requested_by_account` INT UNSIGNED NOT NULL,
  `status` ENUM('pending', 'done', 'failed') NOT NULL DEFAULT 'pending',
  `error` VARCHAR(255) NULL,
  `award_id` CHAR(36) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `processed_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `one_request_per_source_ref` (`source`, `source_ref`),
  KEY `status` (`status`, `id`),
  CONSTRAINT `groot_coin_award_queue_source` CHECK (`source` <> 'gm')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
