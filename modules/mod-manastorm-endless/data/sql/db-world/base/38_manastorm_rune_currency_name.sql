-- CurrencyTypes.dbc row 364 identifies Rune of Ascension as item 375250.
-- Item 111381 is the legacy Mark of Ascension and must not be renamed.
-- Rename the world policy keys without changing payout amounts or flags.
-- Existing RUNES policies take precedence if both old and new keys exist.
-- The source retains the old character ledger keys internally, preserving
-- historical totals/carry; no character migration or first-clear reset is needed.
UPDATE `manastorm_reward_rule` AS `legacy` LEFT JOIN `manastorm_reward_rule` AS `current` ON `current`.`reward_key` = 'RUNES' SET `legacy`.`reward_key` = 'RUNES' WHERE `legacy`.`reward_key` = 'MARKS' AND `current`.`reward_key` IS NULL;

UPDATE `manastorm_reward_rule` AS `legacy` LEFT JOIN `manastorm_reward_rule` AS `current` ON `current`.`reward_key` = 'RUNES_FIRST' SET `legacy`.`reward_key` = 'RUNES_FIRST' WHERE `legacy`.`reward_key` = 'MARKS_FIRST' AND `current`.`reward_key` IS NULL;

DELETE `legacy` FROM `manastorm_reward_rule` AS `legacy` INNER JOIN `manastorm_reward_rule` AS `current` ON (`legacy`.`reward_key` = 'MARKS' AND `current`.`reward_key` = 'RUNES') OR (`legacy`.`reward_key` = 'MARKS_FIRST' AND `current`.`reward_key` = 'RUNES_FIRST');

UPDATE `manastorm_reward_rule` SET `item_entry` = 375250 WHERE `reward_key` IN ('RUNES', 'RUNES_FIRST') AND `item_entry` = 111381;

SELECT * FROM `manastorm_reward_rule` WHERE `reward_key` IN ('RUNES', 'RUNES_FIRST');
