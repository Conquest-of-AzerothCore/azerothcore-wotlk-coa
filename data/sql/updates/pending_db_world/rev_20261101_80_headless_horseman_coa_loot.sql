-- Live CoA drops its own level-60 Headless Horseman loot instead of the stock level-80 rings (SUB creature_loot and
-- Exiles DB, 2026-10-04): the helm and blade at 5%, the four rings at 2.5%. #10560 lowered The Horseman's Seal
-- (49123) to RequiredLevel 60 for #10228, which made an item level 200 ring wearable at the level-60 cap; restore 80.
DELETE FROM `creature_loot_template` WHERE `Entry` = 23682
    AND `Item` IN (49121, 49123, 49124, 2033808, 2033957, 2034073, 2034074, 2034075, 2038175);
INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
`Comment`) VALUES
(23682, 2033808, 0, 5, 0, 1, 0, 1, 1, 'Headless Horseman - The Horseman''s Helm'),
(23682, 2033957, 0, 2.5, 0, 1, 0, 1, 1, 'Headless Horseman - Hallow Band'),
(23682, 2034073, 0, 2.5, 0, 1, 0, 1, 1, 'Headless Horseman - The Horseman''s Signet Ring'),
(23682, 2034074, 0, 2.5, 0, 1, 0, 1, 1, 'Headless Horseman - Witches Band'),
(23682, 2034075, 0, 2.5, 0, 1, 0, 1, 1, 'Headless Horseman - Ring of Ghoulish Delight'),
(23682, 2038175, 0, 5, 0, 1, 0, 1, 1, 'Headless Horseman - The Horseman''s Blade');

UPDATE `item_template` SET `RequiredLevel` = 80 WHERE `entry` = 49123;
