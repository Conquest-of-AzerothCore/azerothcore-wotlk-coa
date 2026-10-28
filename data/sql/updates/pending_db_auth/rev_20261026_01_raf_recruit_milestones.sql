CREATE TABLE IF NOT EXISTS `raf_recruit_claims` (
  `claim_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` INT UNSIGNED NOT NULL,
  `reward_id` INT UNSIGNED NOT NULL,
  `realm_id` INT UNSIGNED NOT NULL,
  `guid` INT UNSIGNED NOT NULL,
  `item_id` INT UNSIGNED NOT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `created_at` BIGINT UNSIGNED NOT NULL,
  `delivered_at` BIGINT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`claim_id`),
  UNIQUE KEY `account_realm_reward` (`account_id`, `realm_id`, `reward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
