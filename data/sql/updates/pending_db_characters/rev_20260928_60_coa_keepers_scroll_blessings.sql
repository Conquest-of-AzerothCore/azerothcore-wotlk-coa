-- Active Keeper's Scroll zone blessings, reloaded at startup so a restart keeps them
CREATE TABLE IF NOT EXISTS `coa_keepers_scroll_blessing` (
  `zone` INT UNSIGNED NOT NULL,
  `instance` INT UNSIGNED NOT NULL,
  `spell` INT UNSIGNED NOT NULL,
  `caster` INT UNSIGNED NOT NULL,
  `team` TINYINT UNSIGNED NOT NULL,
  `expire_at` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`zone`, `instance`, `spell`, `caster`)
) ENGINE=InnoDB;
