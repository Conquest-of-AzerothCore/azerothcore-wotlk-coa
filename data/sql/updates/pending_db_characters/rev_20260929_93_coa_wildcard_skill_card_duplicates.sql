-- Wildcard card packs can hold cards the account already collected, so pending cards get their own numbered rows,
-- collected cards keep the progress their duplicates add, and the account keeps its bonus pack progress and how
-- often it bought each kind of sealed card (the price rises with every purchase).
CREATE TABLE IF NOT EXISTS `coa_wildcard_skill_card_pending` (
  `account` INT UNSIGNED NOT NULL,
  `id` INT UNSIGNED NOT NULL,
  `card` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`account`, `id`)
);

DELETE FROM `coa_wildcard_skill_card_pending`;
INSERT INTO `coa_wildcard_skill_card_pending` (`account`, `id`, `card`)
  SELECT `account`, `card`, `card` FROM `coa_wildcard_skill_card` WHERE `pending` = 1;
DELETE FROM `coa_wildcard_skill_card` WHERE `pending` = 1;
ALTER TABLE `coa_wildcard_skill_card`
  DROP COLUMN `pending`,
  ADD COLUMN `progress` INT UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `coa_wildcard_skill_card_account` (
  `account` INT UNSIGNED NOT NULL,
  `bonus_progress` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
);

CREATE TABLE IF NOT EXISTS `coa_wildcard_skill_card_purchase` (
  `account` INT UNSIGNED NOT NULL,
  `type` TINYINT UNSIGNED NOT NULL,
  `count` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`, `type`)
);
