CREATE TABLE IF NOT EXISTS `recruit_rewards` (
  `reward_id` INT UNSIGNED NOT NULL,
  `required_recruits` INT UNSIGNED NOT NULL,
  `realm_mode_mask` TINYINT UNSIGNED NOT NULL DEFAULT 15 COMMENT '1=CoA, 2=Freepick, 4=Warcraft Reborn, 8=Wildcard; combine bits',
  `item_id` INT UNSIGNED NOT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`reward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
