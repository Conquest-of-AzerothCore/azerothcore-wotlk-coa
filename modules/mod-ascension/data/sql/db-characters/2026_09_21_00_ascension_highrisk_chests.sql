-- Escrow for High-Risk death chests. Never drop populated tables.
CREATE TABLE IF NOT EXISTS `highrisk_chest` (
  `id` bigint unsigned NOT NULL,
  `owner` int unsigned NOT NULL,
  `map` smallint unsigned NOT NULL,
  `phase` int unsigned NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `o` float NOT NULL,
  `gold` int unsigned NOT NULL,
  `original_gold` int unsigned NOT NULL,
  `gold_claimant` int unsigned NOT NULL DEFAULT 0,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gold_claimed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `highrisk_chest_item` (
  `chest_id` bigint unsigned NOT NULL,
  `slot` tinyint unsigned NOT NULL,
  `item_guid` int unsigned NOT NULL,
  `entry` int unsigned NOT NULL,
  `count` int unsigned NOT NULL,
  `claimant` int unsigned NOT NULL DEFAULT 0,
  `claimed_at` timestamp NULL DEFAULT NULL,
  `active_item_guid` int unsigned GENERATED ALWAYS AS (IF(`claimant`=0,`item_guid`,NULL)) STORED,
  PRIMARY KEY (`chest_id`,`slot`),
  UNIQUE KEY `one_active_deposit` (`active_item_guid`),
  KEY `unclaimed` (`claimant`,`item_guid`),
  CONSTRAINT `fk_highrisk_chest_item` FOREIGN KEY (`chest_id`) REFERENCES `highrisk_chest` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
