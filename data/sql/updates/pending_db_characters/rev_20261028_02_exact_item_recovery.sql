CREATE TABLE IF NOT EXISTS `recovery_item_snapshot` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_guid` INT UNSIGNED NOT NULL,
  `original_guid` INT UNSIGNED NOT NULL,
  `source` TINYINT UNSIGNED NOT NULL,
  `item_entry` INT UNSIGNED NOT NULL,
  `item_count` INT UNSIGNED NOT NULL,
  `price` INT UNSIGNED NOT NULL,
  `created_at` INT UNSIGNED NOT NULL,
  `item_values` TEXT NOT NULL,
  `item_text` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_guid`, `id`),
  KEY `owner_source_id` (`owner_guid`, `source`, `id`),
  KEY `owner_original_source` (`owner_guid`, `original_guid`, `source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `recovery_item_snapshot_receipt` (
  `recovery_id` BIGINT UNSIGNED NOT NULL,
  `owner_guid` INT UNSIGNED NOT NULL,
  `mail_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`recovery_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
