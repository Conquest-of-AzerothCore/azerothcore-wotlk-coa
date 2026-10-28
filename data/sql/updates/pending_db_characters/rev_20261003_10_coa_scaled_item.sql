-- Lifted copies of world items handed out by level-scaled creatures, chests and quests,
-- keyed by their item template entry.
CREATE TABLE IF NOT EXISTS `coa_scaled_item` (
  `entry` INT UNSIGNED NOT NULL,
  `base_entry` INT UNSIGNED NOT NULL,
  `lift` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`entry`),
  UNIQUE KEY `base_lift` (`base_entry`, `lift`)
);
