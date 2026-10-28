-- Apply to acore_world after SQL 38 and 39.
-- User-selected first-clear cache contents and currency scaling.
-- Preserve other item flags; one gold is exactly 10000 copper (scoped source rate exemption).
UPDATE `item_template` SET `Flags` = `Flags` | 4, `minMoneyLoot` = 10000, `maxMoneyLoot` = 10000 WHERE `entry` = 1478052;

DELETE FROM `item_loot_template` WHERE `Entry` = 1478052;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(1478052, 97885, 0, 100, 0, 1, 0, 1, 1, 'Bonus Manastorm Cache: Ability Sealed Card Pack'),
(1478052, 97886, 0, 100, 0, 1, 0, 1, 1, 'Bonus Manastorm Cache: Talent Sealed Card Pack'),
(1478052, 1278049, 0, 100, 0, 1, 0, 1, 1, 'Bonus Manastorm Cache: Case of Fortune'),
(1478052, 1278048, 0, 100, 0, 1, 0, 1, 1, 'Bonus Manastorm Cache: Case of Fortune Talents');

DELETE FROM `manastorm_reward_rule` WHERE `reward_key` = 'BONUS_CACHE';
INSERT INTO `manastorm_reward_rule` (`reward_key`, `item_entry`, `base_amount`, `depth_step`, `amount_per_step`, `first_clear_only`, `apply_group_multiplier`, `apply_segment_multiplier`, `enabled`) VALUES
('BONUS_CACHE', 1478052, 1, 1, 0, 1, 0, 0, 1);

UPDATE `manastorm_reward_rule` SET `apply_group_multiplier` = 1, `apply_segment_multiplier` = 1 WHERE `reward_key` IN ('RUNES', 'RUNES_FIRST');
