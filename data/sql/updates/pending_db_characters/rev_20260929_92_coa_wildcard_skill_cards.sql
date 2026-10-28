-- Wildcard skill cards were bound to the account for the season. `pending` cards came out of a pack and wait to be
-- revealed; the others belong to the collection.
CREATE TABLE IF NOT EXISTS `coa_wildcard_skill_card` (
  `account` INT UNSIGNED NOT NULL,
  `card` INT UNSIGNED NOT NULL,
  `pending` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`, `card`)
);
