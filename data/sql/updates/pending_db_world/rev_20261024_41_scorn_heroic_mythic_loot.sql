-- Scorn (Heroic 114693, Mythic 214693) still used his Normal loot list (14693: rare item level 35 items). Like the
-- bosses of rev_20261016_30, each tier now drops one of his three items in its own tier per kill: Heroic 1523168-70
-- (item level 61), Mythic 1623168-70 (item level 64).
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (114693, 214693);
DELETE FROM `creature_loot_template` WHERE `Entry` IN (114693, 214693);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114693, 1523168, 0, 0, 0, 1, 1, 1, 1, 'Scorn (Heroic) - Scorn''s Focal Dagger'),
(114693, 1523169, 0, 0, 0, 1, 1, 1, 1, 'Scorn (Heroic) - Scorn''s Icy Choker'),
(114693, 1523170, 0, 0, 0, 1, 1, 1, 1, 'Scorn (Heroic) - The Frozen Clutch'),
(214693, 1623168, 0, 0, 0, 1, 1, 1, 1, 'Scorn (Mythic) - Scorn''s Focal Dagger'),
(214693, 1623169, 0, 0, 0, 1, 1, 1, 1, 'Scorn (Mythic) - Scorn''s Icy Choker'),
(214693, 1623170, 0, 0, 0, 1, 1, 1, 1, 'Scorn (Mythic) - The Frozen Clutch');
