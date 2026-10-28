-- The Wildcard Specialization Cache (item 2977359) came once per account, to its first character on the realm.
CREATE TABLE IF NOT EXISTS `coa_wildcard_specialization_cache` (
  `account` INT UNSIGNED NOT NULL,
  `claimed_at` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`account`)
);
