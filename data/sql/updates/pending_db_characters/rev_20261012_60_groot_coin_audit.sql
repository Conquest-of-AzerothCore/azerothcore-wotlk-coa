-- Groot Coin audit records. These tables are append-only history: nothing here is ever dropped or rewritten, so
-- replaying this file keeps every award and exchange, and no foreign key removes history with a deleted character.

-- One row per delivered award. The unique key is the duplicate guard: an account is paid once per issue.
CREATE TABLE IF NOT EXISTS `grootcoin_award` (
  `award_id` CHAR(36) NOT NULL,
  `issue_number` INT UNSIGNED NOT NULL,
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

-- One row per committed exchange, with the rate that applied.
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

-- The item stacks an exchange debited and credited. `stored_count` is what the database held for the stack when
-- the exchange ran (-1: no such stack) and `expected_count` what the server had in memory; the CHECK makes the
-- whole exchange fail, with nothing changed, when the two differ or the target slot is taken.
CREATE TABLE IF NOT EXISTS `grootcoin_exchange_item` (
  `exchange_id` CHAR(36) NOT NULL,
  `item_guid` INT UNSIGNED NOT NULL,
  `item_entry` INT UNSIGNED NOT NULL,
  `expected_count` BIGINT NOT NULL,
  `stored_count` BIGINT NOT NULL,
  `resulting_count` INT UNSIGNED NOT NULL,
  `slot_conflicts` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`exchange_id`, `item_guid`),
  KEY `item` (`item_guid`),
  CONSTRAINT `grootcoin_exchange_item_matches_inventory`
    CHECK (`stored_count` = `expected_count` AND `slot_conflicts` = 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
