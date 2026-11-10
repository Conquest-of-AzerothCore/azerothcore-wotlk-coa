-- The holiday dungeon reward boxes still held stock level-80 gear that no character on a level-60 realm can wear.
-- Keg-Shaped Treasure Chest (54535): Tankard O' Terror 48663 becomes the CoA level-60 Tankard O' Terror 2048663 at
-- the same 8%; Direbrew's Bloody Shanker 49120 has no CoA version and leaves the box.
DELETE FROM `item_loot_template` WHERE `Entry` = 54535 AND `Item` IN (48663, 49120, 2048663);
INSERT INTO `item_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
`Comment`) VALUES
(54535, 2048663, 0, 8, 0, 1, 0, 1, 1, 'Keg-Shaped Treasure Chest - Tankard O'' Terror');

-- Loot-Filled Pumpkin (54516): The Horseman's Horrific Helm 49126 and Baleful Blade 49128 have no CoA version.
DELETE FROM `item_loot_template` WHERE `Entry` = 54516 AND `Item` IN (49126, 49128);

-- Heart-Shaped Box (54537): the level-80 neck reference 50010 has no CoA counterpart for the box.
DELETE FROM `item_loot_template` WHERE `Entry` = 54537 AND `Reference` = 50010;
