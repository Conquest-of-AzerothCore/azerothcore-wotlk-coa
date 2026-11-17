-- Voodoo Devotees (Innocents for Sinners 1660023, Valley of Trials) dropped nothing: the creature had no loot table
-- and no coin. As the Cain estate and Three Totems mobs, it takes a stock analogue of its kind, zone and level, the
-- Burning Blade Yarrog Baneshadow 3183 of the Valley of Trials without his quest item, and his coin.
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 1, `maxgold` = 7 WHERE `entry` = 161807;
DELETE FROM `creature_loot_template` WHERE `Entry` = 161807;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(161807, 0, 20000, 30, 0, 1, 1, 1, 1, 'Voodoo Devotee - as Yarrog Baneshadow 3183'),
(161807, 0, 20015, 30, 0, 1, 0, 1, 1, 'Voodoo Devotee - as Yarrog Baneshadow 3183'),
(161807, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Voodoo Devotee - as Yarrog Baneshadow 3183');
