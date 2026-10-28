-- Scaling level of each item instance that keeps its authored entry and takes its stats from the
-- ItemStat.dbc ladder row for that level, keyed by the item instance guid.
CREATE TABLE IF NOT EXISTS `character_item_scaling` (
  `item_guid` INT UNSIGNED NOT NULL,
  `item_entry` INT UNSIGNED NOT NULL,
  `scaling_level` TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (`item_guid`)
);
