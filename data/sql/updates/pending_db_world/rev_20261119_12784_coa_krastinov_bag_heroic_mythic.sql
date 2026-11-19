-- Krastinov's Bag of Horrors 13725 (#12784): Krastinov's Bag of Horrors 5515 needs the bag from Jandice Barov. Her
-- Normal loot 10503 pays it at 100% to players on the quest, but the Heroic and Mythic lists 110503 and 210503 that
-- rev_20261009_70 rewrote hold no quest item, so a Heroic or Mythic kill never drops it. Mirror the Normal row.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (110503, 210503) AND `Item` = 13725;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(110503, 13725, 0, 100, 1, 1, 0, 1, 1, 'Jandice Barov (Heroic) - Krastinov''s Bag of Horrors'),
(210503, 13725, 0, 100, 1, 1, 0, 1, 1, 'Jandice Barov (Mythic) - Krastinov''s Bag of Horrors');
