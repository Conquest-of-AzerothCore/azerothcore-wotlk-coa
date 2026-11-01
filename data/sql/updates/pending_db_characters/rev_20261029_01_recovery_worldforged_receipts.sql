CREATE TABLE IF NOT EXISTS `recovery_worldforged_receipt` (
  `offer_id` INT UNSIGNED NOT NULL,
  `item_guid` INT UNSIGNED NOT NULL,
  `owner_guid` INT UNSIGNED NOT NULL,
  `mail_id` INT UNSIGNED NOT NULL,
  `required_item` INT UNSIGNED NOT NULL,
  `refunded_item` INT UNSIGNED NOT NULL,
  `rune_count` INT UNSIGNED NOT NULL,
  `claimed_at` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`offer_id`, `item_guid`),
  KEY `owner_guid` (`owner_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
