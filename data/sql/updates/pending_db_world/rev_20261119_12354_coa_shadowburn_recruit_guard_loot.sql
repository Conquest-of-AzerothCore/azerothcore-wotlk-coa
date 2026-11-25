-- Shadowburn Recruit and Shadowburn Guard drop gold, cloth, food and CoA World Loot like Braicag Ealdir,
-- the level 27-28 humanoid of Pale Reach whose table the earlier Pale Reach port filled.
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 37, `maxgold` = 129
WHERE `entry` IN (164476, 164489)
    AND `lootid` = 0;

DELETE FROM `creature_loot_template` WHERE `Entry` IN (164476, 164489);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
    `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164476, 1, 1000127, 0, 0, 1, 5, 1, 1, 'Shadowburn Recruit - World Loot Level 27'),
(164476, 2, 1000128, 0, 0, 1, 5, 1, 1, 'Shadowburn Recruit - World Loot Level 28'),
(164476, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Shadowburn Recruit - Melon Juice'),
(164476, 2589, 0, 12.54, 0, 1, 0, 1, 3, 'Shadowburn Recruit - Linen Cloth'),
(164476, 2592, 0, 10.16, 0, 1, 0, 1, 2, 'Shadowburn Recruit - Wool Cloth'),
(164476, 4306, 0, 22.98, 0, 1, 0, 1, 2, 'Shadowburn Recruit - Silk Cloth'),
(164489, 1, 1000128, 0, 0, 1, 5, 1, 1, 'Shadowburn Guard - World Loot Level 28'),
(164489, 2, 1000129, 0, 0, 1, 5, 1, 1, 'Shadowburn Guard - World Loot Level 29'),
(164489, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Shadowburn Guard - Melon Juice'),
(164489, 2589, 0, 12.54, 0, 1, 0, 1, 3, 'Shadowburn Guard - Linen Cloth'),
(164489, 2592, 0, 10.16, 0, 1, 0, 1, 2, 'Shadowburn Guard - Wool Cloth'),
(164489, 4306, 0, 22.98, 0, 1, 0, 1, 2, 'Shadowburn Guard - Silk Cloth');
