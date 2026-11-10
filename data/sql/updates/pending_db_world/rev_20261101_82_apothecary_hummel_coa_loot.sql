-- Live CoA drops its own level-60 Apothecary Hummel loot instead of the stock guaranteed level-80 neck
-- (reference 50010) (SUB creature_loot, 2026-10-04): the five necks at 2%, Forever-Lovely Rose, Vile Fumigator's Mask
-- and The Heartbreaker at 5%.
DELETE FROM `creature_loot_template` WHERE `Entry` = 36296 AND `Reference` = 50010;
DELETE FROM `creature_loot_template` WHERE `Entry` = 36296
    AND `Item` IN (50471, 388912, 392168, 397120, 397132, 397144, 397156, 397168);
INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
`Comment`) VALUES
(36296, 50471, 0, 5, 0, 1, 0, 1, 1, 'Apothecary Hummel - The Heartbreaker'),
(36296, 388912, 0, 5, 0, 1, 0, 1, 1, 'Apothecary Hummel - Forever-Lovely Rose'),
(36296, 392168, 0, 5, 0, 1, 0, 1, 1, 'Apothecary Hummel - Vile Fumigator''s Mask'),
(36296, 397120, 0, 2, 0, 1, 0, 1, 1, 'Apothecary Hummel - Winking Eye of Love'),
(36296, 397132, 0, 2, 0, 1, 0, 1, 1, 'Apothecary Hummel - Heartbreak Charm'),
(36296, 397144, 0, 2, 0, 1, 0, 1, 1, 'Apothecary Hummel - Shard of Pirouetting Happiness'),
(36296, 397156, 0, 2, 0, 1, 0, 1, 1, 'Apothecary Hummel - Sweet Perfume Broach'),
(36296, 397168, 0, 2, 0, 1, 0, 1, 1, 'Apothecary Hummel - Choker of the Pure Heart');
