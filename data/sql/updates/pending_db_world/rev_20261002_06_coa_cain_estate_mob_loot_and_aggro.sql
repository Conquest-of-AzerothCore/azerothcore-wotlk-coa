-- Cain estate CoA mobs dropped nothing and pulled from twice Deathknell's range (playtest). No source records CoA's
-- drops or aggro (the Exiles rows are empty placeholders), so each takes a stock analogue of its kind and level:
-- Kobold Desecrator the Kobold Worker 257, Ghoul, Zombie and the Brainless the Rattlecage Skeleton 1890, the
-- Aberrant Progeny the Rot Hide Graverobber 1941, without those tables' quest items. Necrotic Bears drop low-level
-- bear trash at stock bear rates and no coin. Aggro range is Deathknell's stock 10 yd; the Progeny boss, 15.
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 1, `maxgold` = 5, `detection_range` = 10
    WHERE `entry` IN (161749, 161751, 161752);
UPDATE `creature_template` SET `mingold` = 1, `maxgold` = 5, `detection_range` = 10
    WHERE `entry` IN (161753, 161754, 161755);
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 0, `maxgold` = 0, `detection_range` = 10
    WHERE `entry` = 161743;
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 10, `maxgold` = 25, `detection_range` = 15
    WHERE `entry` = 161757;
DELETE FROM `creature_loot_template` WHERE `Entry` IN (161743, 161749, 161751, 161752, 161757)
    OR (`Entry` IN (161753, 161754, 161755) AND `Item` IN (0, 3262));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(161743, 4865, 0, 30, 0, 1, 0, 1, 1, 'Necrotic Bear - Ruined Pelt'),
(161743, 3169, 0, 15, 0, 1, 0, 1, 1, 'Necrotic Bear - Chipped Bear Tooth'),
(161743, 11406, 0, 5, 0, 1, 0, 1, 1, 'Necrotic Bear - Rotting Bear Carcass'),
(161751, 0, 20000, 30, 0, 1, 1, 1, 1, 'Kobold Desecrator - as Kobold Worker 257'),
(161751, 0, 20014, 30, 0, 1, 0, 1, 1, 'Kobold Desecrator - as Kobold Worker 257'),
(161751, 755, 0, 20, 0, 1, 0, 1, 1, 'Kobold Desecrator - Melted Candle, as Kobold Worker 257'),
(161751, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Kobold Desecrator - as Kobold Worker 257'),
(161749, 0, 20000, 30, 0, 1, 0, 1, 1, 'Zombie - as Rattlecage Skeleton 1890'),
(161749, 0, 20016, 30, 0, 1, 0, 1, 1, 'Zombie - as Rattlecage Skeleton 1890'),
(161749, 3262, 0, 2, 0, 1, 0, 1, 1, 'Zombie - Putrid Wooden Hammer, as Rattlecage Skeleton 1890'),
(161749, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Zombie - as Rattlecage Skeleton 1890'),
(161752, 0, 20000, 30, 0, 1, 0, 1, 1, 'Ghoul - as Rattlecage Skeleton 1890'),
(161752, 0, 20016, 30, 0, 1, 0, 1, 1, 'Ghoul - as Rattlecage Skeleton 1890'),
(161752, 3262, 0, 2, 0, 1, 0, 1, 1, 'Ghoul - Putrid Wooden Hammer, as Rattlecage Skeleton 1890'),
(161752, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Ghoul - as Rattlecage Skeleton 1890'),
(161753, 0, 20000, 30, 0, 1, 0, 1, 1, 'Brainless Majordomo - as Rattlecage Skeleton 1890'),
(161753, 0, 20016, 30, 0, 1, 0, 1, 1, 'Brainless Majordomo - as Rattlecage Skeleton 1890'),
(161753, 3262, 0, 2, 0, 1, 0, 1, 1, 'Brainless Majordomo - Putrid Wooden Hammer, as Rattlecage Skeleton 1890'),
(161753, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Brainless Majordomo - as Rattlecage Skeleton 1890'),
(161754, 0, 20000, 30, 0, 1, 0, 1, 1, 'Brainless Maid - as Rattlecage Skeleton 1890'),
(161754, 0, 20016, 30, 0, 1, 0, 1, 1, 'Brainless Maid - as Rattlecage Skeleton 1890'),
(161754, 3262, 0, 2, 0, 1, 0, 1, 1, 'Brainless Maid - Putrid Wooden Hammer, as Rattlecage Skeleton 1890'),
(161754, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Brainless Maid - as Rattlecage Skeleton 1890'),
(161755, 0, 20000, 30, 0, 1, 0, 1, 1, 'Brainless Stablemaster - as Rattlecage Skeleton 1890'),
(161755, 0, 20016, 30, 0, 1, 0, 1, 1, 'Brainless Stablemaster - as Rattlecage Skeleton 1890'),
(161755, 3262, 0, 2, 0, 1, 0, 1, 1, 'Brainless Stablemaster - Putrid Wooden Hammer, as Rattlecage Skeleton 1890'),
(161755, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Brainless Stablemaster - as Rattlecage Skeleton 1890'),
(161757, 2589, 0, 29.6397, 0, 1, 0, 1, 2, 'Aberrant Progeny - Linen Cloth, as Rot Hide Graverobber 1941'),
(161757, 4604, 0, 7.7165, 0, 1, 0, 1, 1, 'Aberrant Progeny - Forest Mushroom Cap, as Rot Hide Graverobber 1941'),
(161757, 159, 0, 3.4324, 0, 1, 0, 1, 1, 'Aberrant Progeny - Refreshing Spring Water, as Rot Hide Graverobber 1941'),
(161757, 117, 0, 0.02, 0, 1, 0, 1, 1, 'Aberrant Progeny - Tough Jerky, as Rot Hide Graverobber 1941');
