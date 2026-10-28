CREATE TABLE IF NOT EXISTS `raf_recruit_reward_delivery` (
  `claim_id` BIGINT UNSIGNED NOT NULL,
  `account_id` INT UNSIGNED NOT NULL,
  `guid` INT UNSIGNED NOT NULL,
  `mail_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`claim_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
