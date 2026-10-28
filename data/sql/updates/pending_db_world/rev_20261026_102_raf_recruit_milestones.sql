CREATE TABLE IF NOT EXISTS `recruit_milestone_rewards` (
  `reward_id` INT UNSIGNED NOT NULL,
  `required_level` TINYINT UNSIGNED NOT NULL,
  `realm_mode_mask` TINYINT UNSIGNED NOT NULL DEFAULT 15,
  `item_id` INT UNSIGNED NOT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`reward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `recruit_milestone_rewards`
(`reward_id`, `required_level`, `realm_mode_mask`, `item_id`, `quantity`, `enabled`) VALUES
(1, 10, 15, 10050, 4, 1),
(2, 60, 15, 414010, 1, 1);
