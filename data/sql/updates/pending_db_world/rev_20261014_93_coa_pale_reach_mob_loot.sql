-- Pale Reach mob loot, built the way the CoA world builds it. For every attackable Pale Reach mob: the World Loot
-- Level tables for its levels (one rolled per kill), the drops of the game's own mobs of its type and level (cloth,
-- food, claws...) and of its family (tusks, candles, fins, crab meat...). Quest drops and the zone's own items stay.
-- Wild Ealdir (level 18-19, humanoid)
UPDATE `creature_template` SET `lootid` = 164004 WHERE `entry` = 164004;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164004 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164004, 1, 1000118, 0, 0, 1, 5, 1, 1, 'Wild Ealdir - World Loot Level 18'),
(164004, 2, 1000119, 0, 0, 1, 5, 1, 1, 'Wild Ealdir - World Loot Level 19'),
(164004, 2589, 0, 17.94, 0, 1, 0, 1, 3, 'Wild Ealdir - Linen Cloth'),
(164004, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Wild Ealdir - Ice Cold Milk'),
(164004, 2592, 0, 20.19, 0, 1, 0, 1, 2, 'Wild Ealdir - Wool Cloth'),
(164004, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Wild Ealdir - Melon Juice');
-- Road Bandit (level 17-18, humanoid)
UPDATE `creature_template` SET `lootid` = 164020 WHERE `entry` = 164020;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164020 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164020, 1, 1000117, 0, 0, 1, 5, 1, 1, 'Road Bandit - World Loot Level 17'),
(164020, 2, 1000118, 0, 0, 1, 5, 1, 1, 'Road Bandit - World Loot Level 18'),
(164020, 2589, 0, 18.83, 0, 1, 0, 1, 3, 'Road Bandit - Linen Cloth'),
(164020, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Road Bandit - Ice Cold Milk'),
(164020, 2592, 0, 19.97, 0, 1, 0, 1, 2, 'Road Bandit - Wool Cloth');
-- Road Marauder (level 17-18, humanoid)
UPDATE `creature_template` SET `lootid` = 164021 WHERE `entry` = 164021;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164021 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164021, 1, 1000117, 0, 0, 1, 5, 1, 1, 'Road Marauder - World Loot Level 17'),
(164021, 2, 1000118, 0, 0, 1, 5, 1, 1, 'Road Marauder - World Loot Level 18'),
(164021, 2589, 0, 18.83, 0, 1, 0, 1, 3, 'Road Marauder - Linen Cloth'),
(164021, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Road Marauder - Ice Cold Milk'),
(164021, 2592, 0, 19.97, 0, 1, 0, 1, 2, 'Road Marauder - Wool Cloth');
-- Shadewell Murloc Raider (level 18-19, murloc)
UPDATE `creature_template` SET `lootid` = 164023 WHERE `entry` = 164023;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164023 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164023, 1, 1000118, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Raider - World Loot Level 18'),
(164023, 2, 1000119, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Raider - World Loot Level 19'),
(164023, 2589, 0, 17.94, 0, 1, 0, 1, 3, 'Shadewell Murloc Raider - Linen Cloth'),
(164023, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Shadewell Murloc Raider - Ice Cold Milk'),
(164023, 2592, 0, 20.19, 0, 1, 0, 1, 2, 'Shadewell Murloc Raider - Wool Cloth'),
(164023, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Shadewell Murloc Raider - Melon Juice'),
(164023, 1468, 0, 33.33, 0, 1, 0, 1, 1, 'Shadewell Murloc Raider - Murloc Fin'),
(164023, 730, 0, 36.13, 0, 1, 0, 1, 1, 'Shadewell Murloc Raider - Murloc Eye'),
(164023, 5523, 0, 36.6, 0, 1, 0, 1, 1, 'Shadewell Murloc Raider - Small Barnacled Clam'),
(164023, 6289, 0, 4.75, 0, 1, 0, 1, 3, 'Shadewell Murloc Raider - Raw Longjaw Mud Snapper');
-- Shadewell Murloc Seer (level 18-19, murloc)
UPDATE `creature_template` SET `lootid` = 164024 WHERE `entry` = 164024;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164024 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164024, 1, 1000118, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Seer - World Loot Level 18'),
(164024, 2, 1000119, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Seer - World Loot Level 19'),
(164024, 2589, 0, 17.94, 0, 1, 0, 1, 3, 'Shadewell Murloc Seer - Linen Cloth'),
(164024, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Shadewell Murloc Seer - Ice Cold Milk'),
(164024, 2592, 0, 20.19, 0, 1, 0, 1, 2, 'Shadewell Murloc Seer - Wool Cloth'),
(164024, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Shadewell Murloc Seer - Melon Juice'),
(164024, 1468, 0, 33.33, 0, 1, 0, 1, 1, 'Shadewell Murloc Seer - Murloc Fin'),
(164024, 730, 0, 36.13, 0, 1, 0, 1, 1, 'Shadewell Murloc Seer - Murloc Eye'),
(164024, 5523, 0, 36.6, 0, 1, 0, 1, 1, 'Shadewell Murloc Seer - Small Barnacled Clam'),
(164024, 6289, 0, 4.75, 0, 1, 0, 1, 3, 'Shadewell Murloc Seer - Raw Longjaw Mud Snapper');
-- Hexed Bloodpaw Gnoll (level 19-20, gnoll)
UPDATE `creature_template` SET `lootid` = 164029 WHERE `entry` = 164029;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164029 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164029, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hexed Bloodpaw Gnoll - World Loot Level 19'),
(164029, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hexed Bloodpaw Gnoll - World Loot Level 20'),
(164029, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hexed Bloodpaw Gnoll - Linen Cloth'),
(164029, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hexed Bloodpaw Gnoll - Wool Cloth'),
(164029, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hexed Bloodpaw Gnoll - Ice Cold Milk'),
(164029, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hexed Bloodpaw Gnoll - Melon Juice'),
(164029, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hexed Bloodpaw Gnoll - Silk Cloth');
-- Bloodpaw Gnoll (level 19-20, gnoll)
UPDATE `creature_template` SET `lootid` = 164030 WHERE `entry` = 164030;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164030 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164030, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Bloodpaw Gnoll - World Loot Level 19'),
(164030, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Bloodpaw Gnoll - World Loot Level 20'),
(164030, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Bloodpaw Gnoll - Linen Cloth'),
(164030, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Bloodpaw Gnoll - Wool Cloth'),
(164030, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Bloodpaw Gnoll - Ice Cold Milk'),
(164030, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Bloodpaw Gnoll - Melon Juice'),
(164030, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Bloodpaw Gnoll - Silk Cloth');
-- Ealdir Dark Druid (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164033 WHERE `entry` = 164033;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164033 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164033, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdir Dark Druid - World Loot Level 21'),
(164033, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdir Dark Druid - World Loot Level 22'),
(164033, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdir Dark Druid - Wool Cloth'),
(164033, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdir Dark Druid - Linen Cloth'),
(164033, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Melon Juice'),
(164033, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Silk Cloth'),
(164033, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Ice Cold Milk');
-- Scadeald Bear (level 20-21, bear)
UPDATE `creature_template` SET `lootid` = 164039 WHERE `entry` = 164039;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164039 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164039, 1, 1000020, 0, 0, 1, 5, 1, 1, 'Scadeald Bear - World Loot Level 20'),
(164039, 2, 1000021, 0, 0, 1, 5, 1, 1, 'Scadeald Bear - World Loot Level 21'),
(164039, 11406, 0, 30.73, 0, 1, 0, 1, 1, 'Scadeald Bear - Rotting Bear Carcass'),
(164039, 2940, 0, 31.18, 0, 1, 0, 1, 1, 'Scadeald Bear - Bloody Bear Paw'),
(164039, 5635, 0, 3.58, 0, 1, 0, 1, 1, 'Scadeald Bear - Sharp Claw'),
(164039, 3173, 0, 38.0, 0, 1, 0, 1, 1, 'Scadeald Bear - Bear Meat'),
(164039, 3170, 0, 29.37, 0, 1, 0, 1, 1, 'Scadeald Bear - Large Bear Tooth'),
(164039, 3169, 0, 29.23, 0, 1, 0, 1, 1, 'Scadeald Bear - Chipped Bear Tooth');
-- Jagged Cave Ealdir (level 18-19, humanoid)
UPDATE `creature_template` SET `lootid` = 164043 WHERE `entry` = 164043;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164043 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164043, 1, 1000118, 0, 0, 1, 5, 1, 1, 'Jagged Cave Ealdir - World Loot Level 18'),
(164043, 2, 1000119, 0, 0, 1, 5, 1, 1, 'Jagged Cave Ealdir - World Loot Level 19'),
(164043, 2589, 0, 17.94, 0, 1, 0, 1, 3, 'Jagged Cave Ealdir - Linen Cloth'),
(164043, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Jagged Cave Ealdir - Ice Cold Milk'),
(164043, 2592, 0, 20.19, 0, 1, 0, 1, 2, 'Jagged Cave Ealdir - Wool Cloth'),
(164043, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Jagged Cave Ealdir - Melon Juice');
-- Cragarn (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164048 WHERE `entry` = 164048;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164048 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164048, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Cragarn - World Loot Level 21'),
(164048, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Cragarn - World Loot Level 22'),
(164048, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Cragarn - Wool Cloth'),
(164048, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Cragarn - Linen Cloth'),
(164048, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Cragarn - Melon Juice'),
(164048, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Cragarn - Silk Cloth'),
(164048, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Cragarn - Ice Cold Milk');
-- Ealdmaine Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164049 WHERE `entry` = 164049;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164049 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164049, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Ealdir - World Loot Level 21'),
(164049, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Ealdir - World Loot Level 22'),
(164049, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Ealdir - Wool Cloth'),
(164049, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Ealdir - Linen Cloth'),
(164049, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Ealdir - Melon Juice'),
(164049, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Ealdir - Silk Cloth'),
(164049, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Ealdir - Ice Cold Milk');
-- Restless Corpse (level 20-21, undead)
UPDATE `creature_template` SET `lootid` = 164051 WHERE `entry` = 164051;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164051 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164051, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Restless Corpse - World Loot Level 20'),
(164051, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Restless Corpse - World Loot Level 21'),
(164051, 2592, 0, 19.24, 0, 1, 0, 1, 2, 'Restless Corpse - Wool Cloth'),
(164051, 2589, 0, 18.67, 0, 1, 0, 1, 3, 'Restless Corpse - Linen Cloth'),
(164051, 1179, 0, 2.57, 0, 1, 0, 1, 1, 'Restless Corpse - Ice Cold Milk'),
(164051, 4605, 0, 5.13, 0, 1, 0, 1, 1, 'Restless Corpse - Red-speckled Mushroom');
-- Exhumed Risen (level 20-21, undead)
UPDATE `creature_template` SET `lootid` = 164052 WHERE `entry` = 164052;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164052 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164052, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Exhumed Risen - World Loot Level 20'),
(164052, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Exhumed Risen - World Loot Level 21'),
(164052, 2592, 0, 19.24, 0, 1, 0, 1, 2, 'Exhumed Risen - Wool Cloth'),
(164052, 2589, 0, 18.67, 0, 1, 0, 1, 3, 'Exhumed Risen - Linen Cloth'),
(164052, 1179, 0, 2.57, 0, 1, 0, 1, 1, 'Exhumed Risen - Ice Cold Milk'),
(164052, 4605, 0, 5.13, 0, 1, 0, 1, 1, 'Exhumed Risen - Red-speckled Mushroom');
-- Sir Aldrin Nublar (level 21-21, undead)
UPDATE `creature_template` SET `lootid` = 164053 WHERE `entry` = 164053;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164053 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164053, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Sir Aldrin Nublar - World Loot Level 21'),
(164053, 2592, 0, 19.1, 0, 1, 0, 1, 2, 'Sir Aldrin Nublar - Wool Cloth'),
(164053, 2589, 0, 18.63, 0, 1, 0, 1, 3, 'Sir Aldrin Nublar - Linen Cloth'),
(164053, 1179, 0, 2.67, 0, 1, 0, 1, 1, 'Sir Aldrin Nublar - Ice Cold Milk'),
(164053, 4605, 0, 5.07, 0, 1, 0, 1, 1, 'Sir Aldrin Nublar - Red-speckled Mushroom'),
(164053, 4606, 0, 4.83, 0, 1, 0, 1, 1, 'Sir Aldrin Nublar - Spongy Morel'),
(164053, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Sir Aldrin Nublar - Melon Juice');
-- Frostmane Ambusher (level 21-22, troll)
UPDATE `creature_template` SET `lootid` = 164061 WHERE `entry` = 164061;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164061 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164061, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Frostmane Ambusher - World Loot Level 21'),
(164061, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Frostmane Ambusher - World Loot Level 22'),
(164061, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Frostmane Ambusher - Wool Cloth'),
(164061, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Frostmane Ambusher - Linen Cloth'),
(164061, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Frostmane Ambusher - Melon Juice'),
(164061, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Frostmane Ambusher - Silk Cloth'),
(164061, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Frostmane Ambusher - Ice Cold Milk');
-- Frostmane Reaper (level 20-21, troll)
UPDATE `creature_template` SET `lootid` = 164062 WHERE `entry` = 164062;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164062 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164062, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Frostmane Reaper - World Loot Level 20'),
(164062, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Frostmane Reaper - World Loot Level 21'),
(164062, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Frostmane Reaper - Linen Cloth'),
(164062, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Frostmane Reaper - Wool Cloth'),
(164062, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Frostmane Reaper - Ice Cold Milk'),
(164062, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Reaper - Melon Juice'),
(164062, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Frostmane Reaper - Silk Cloth');
-- Frostmane Stalker (level 20-21, troll)
UPDATE `creature_template` SET `lootid` = 164063 WHERE `entry` = 164063;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164063 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164063, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Frostmane Stalker - World Loot Level 20'),
(164063, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Frostmane Stalker - World Loot Level 21'),
(164063, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Frostmane Stalker - Linen Cloth'),
(164063, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Frostmane Stalker - Wool Cloth'),
(164063, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Frostmane Stalker - Ice Cold Milk'),
(164063, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Stalker - Melon Juice'),
(164063, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Frostmane Stalker - Silk Cloth');
-- Alta'zin the Ascended (level 24-24, humanoid)
UPDATE `creature_template` SET `lootid` = 164071 WHERE `entry` = 164071;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164071 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164071, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Alta''zin the Ascended - World Loot Level 24'),
(164071, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Alta''zin the Ascended - Wool Cloth'),
(164071, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Alta''zin the Ascended - Melon Juice'),
(164071, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Alta''zin the Ascended - Silk Cloth'),
(164071, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Alta''zin the Ascended - Linen Cloth');
-- Frostmane Ambusher (level 22-23, troll)
UPDATE `creature_template` SET `lootid` = 164073 WHERE `entry` = 164073;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164073 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164073, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Frostmane Ambusher - World Loot Level 22'),
(164073, 2, 1000123, 0, 0, 1, 5, 1, 1, 'Frostmane Ambusher - World Loot Level 23'),
(164073, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Frostmane Ambusher - Wool Cloth'),
(164073, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Frostmane Ambusher - Linen Cloth'),
(164073, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Ambusher - Melon Juice'),
(164073, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Frostmane Ambusher - Silk Cloth'),
(164073, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Ambusher - Ice Cold Milk');
-- Scaidern Ealdir (level 20-21, humanoid)
UPDATE `creature_template` SET `lootid` = 164074 WHERE `entry` = 164074;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164074 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164074, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Scaidern Ealdir - World Loot Level 20'),
(164074, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Scaidern Ealdir - World Loot Level 21'),
(164074, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Scaidern Ealdir - Linen Cloth'),
(164074, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Scaidern Ealdir - Wool Cloth'),
(164074, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Scaidern Ealdir - Ice Cold Milk'),
(164074, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Scaidern Ealdir - Melon Juice'),
(164074, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Scaidern Ealdir - Silk Cloth');
-- Chieftain Rallagh (level 22-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164075 WHERE `entry` = 164075;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164075 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164075, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Chieftain Rallagh - World Loot Level 22'),
(164075, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Chieftain Rallagh - Wool Cloth'),
(164075, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Chieftain Rallagh - Linen Cloth'),
(164075, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Chieftain Rallagh - Melon Juice'),
(164075, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Chieftain Rallagh - Silk Cloth'),
(164075, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Chieftain Rallagh - Ice Cold Milk');
-- Galdaern Ealdir (level 20-21, humanoid)
UPDATE `creature_template` SET `lootid` = 164076 WHERE `entry` = 164076;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164076 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164076, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Galdaern Ealdir - World Loot Level 20'),
(164076, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Galdaern Ealdir - World Loot Level 21'),
(164076, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Galdaern Ealdir - Linen Cloth'),
(164076, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Galdaern Ealdir - Wool Cloth'),
(164076, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Galdaern Ealdir - Ice Cold Milk'),
(164076, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Galdaern Ealdir - Melon Juice'),
(164076, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Galdaern Ealdir - Silk Cloth');
-- Chieftain Thornad (level 22-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164077 WHERE `entry` = 164077;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164077 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164077, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Chieftain Thornad - World Loot Level 22'),
(164077, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Chieftain Thornad - Wool Cloth'),
(164077, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Chieftain Thornad - Linen Cloth'),
(164077, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Chieftain Thornad - Melon Juice'),
(164077, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Chieftain Thornad - Silk Cloth'),
(164077, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Chieftain Thornad - Ice Cold Milk');
-- Ealdir Dark Druid (level 20-21, humanoid)
UPDATE `creature_template` SET `lootid` = 164081 WHERE `entry` = 164081;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164081 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164081, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Ealdir Dark Druid - World Loot Level 20'),
(164081, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdir Dark Druid - World Loot Level 21'),
(164081, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Ealdir Dark Druid - Linen Cloth'),
(164081, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Ealdir Dark Druid - Wool Cloth'),
(164081, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Ice Cold Milk'),
(164081, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Melon Juice'),
(164081, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Ealdir Dark Druid - Silk Cloth');
-- Scadeald Fox (level 21-21, wolf)
UPDATE `creature_template` SET `lootid` = 164083 WHERE `entry` = 164083;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164083 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164083, 1, 1000021, 0, 0, 1, 5, 1, 1, 'Scadeald Fox - World Loot Level 21'),
(164083, 5635, 0, 4.99, 0, 1, 0, 1, 1, 'Scadeald Fox - Sharp Claw'),
(164083, 3301, 0, 24.99, 0, 1, 0, 1, 1, 'Scadeald Fox - Sharp Canine'),
(164083, 3299, 0, 16.38, 0, 1, 0, 1, 1, 'Scadeald Fox - Fractured Canine'),
(164083, 3402, 0, 22.25, 0, 1, 0, 1, 1, 'Scadeald Fox - Soft Patch of Fur');
-- Scadeald Wolf (level 17-18, wolf)
UPDATE `creature_template` SET `lootid` = 164084 WHERE `entry` = 164084;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164084 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164084, 1, 1000017, 0, 0, 1, 5, 1, 1, 'Scadeald Wolf - World Loot Level 17'),
(164084, 2, 1000018, 0, 0, 1, 5, 1, 1, 'Scadeald Wolf - World Loot Level 18'),
(164084, 5635, 0, 3.45, 0, 1, 0, 1, 1, 'Scadeald Wolf - Sharp Claw'),
(164084, 3301, 0, 24.8, 0, 1, 0, 1, 1, 'Scadeald Wolf - Sharp Canine'),
(164084, 3402, 0, 18.72, 0, 1, 0, 1, 1, 'Scadeald Wolf - Soft Patch of Fur'),
(164084, 1015, 0, 54.77, 0, 1, 0, 1, 1, 'Scadeald Wolf - Lean Wolf Flank'),
(164084, 3299, 0, 15.61, 0, 1, 0, 1, 1, 'Scadeald Wolf - Fractured Canine'),
(164084, 3300, 0, 24.43, 0, 1, 0, 1, 1, 'Scadeald Wolf - Rabbit''s Foot'),
(164084, 2672, 0, 80.62, 0, 1, 0, 1, 1, 'Scadeald Wolf - Stringy Wolf Meat');
-- Scadeald Eagle (level 19-20, bird)
UPDATE `creature_template` SET `lootid` = 164086 WHERE `entry` = 164086;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164086 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164086, 1, 1000019, 0, 0, 1, 5, 1, 1, 'Scadeald Eagle - World Loot Level 19'),
(164086, 2, 1000020, 0, 0, 1, 5, 1, 1, 'Scadeald Eagle - World Loot Level 20'),
(164086, 6889, 0, 60.58, 0, 1, 0, 1, 1, 'Scadeald Eagle - Small Egg'),
(164086, 4776, 0, 6.44, 0, 1, 0, 1, 1, 'Scadeald Eagle - Ruffled Feather'),
(164086, 4775, 0, 21.68, 0, 1, 0, 1, 1, 'Scadeald Eagle - Cracked Bill'),
(164086, 17056, 0, 30.06, 0, 1, 0, 1, 1, 'Scadeald Eagle - Light Feather');
-- Frostmane Reaper (level 21-22, troll)
UPDATE `creature_template` SET `lootid` = 164088 WHERE `entry` = 164088;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164088 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164088, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Frostmane Reaper - World Loot Level 21'),
(164088, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Frostmane Reaper - World Loot Level 22'),
(164088, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Frostmane Reaper - Wool Cloth'),
(164088, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Frostmane Reaper - Linen Cloth'),
(164088, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Frostmane Reaper - Melon Juice'),
(164088, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Frostmane Reaper - Silk Cloth'),
(164088, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Frostmane Reaper - Ice Cold Milk');
-- Shadewell Murloc Warrior (level 21-22, murloc)
UPDATE `creature_template` SET `lootid` = 164154 WHERE `entry` = 164154;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164154 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164154, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Warrior - World Loot Level 21'),
(164154, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Warrior - World Loot Level 22'),
(164154, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Shadewell Murloc Warrior - Wool Cloth'),
(164154, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Shadewell Murloc Warrior - Linen Cloth'),
(164154, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Shadewell Murloc Warrior - Melon Juice'),
(164154, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Warrior - Silk Cloth'),
(164154, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Shadewell Murloc Warrior - Ice Cold Milk'),
(164154, 1468, 0, 33.33, 0, 1, 0, 1, 1, 'Shadewell Murloc Warrior - Murloc Fin'),
(164154, 730, 0, 36.13, 0, 1, 0, 1, 1, 'Shadewell Murloc Warrior - Murloc Eye'),
(164154, 5523, 0, 36.6, 0, 1, 0, 1, 1, 'Shadewell Murloc Warrior - Small Barnacled Clam'),
(164154, 6289, 0, 4.75, 0, 1, 0, 1, 3, 'Shadewell Murloc Warrior - Raw Longjaw Mud Snapper');
-- Shadewell Murloc Augur (level 21-22, murloc)
UPDATE `creature_template` SET `lootid` = 164155 WHERE `entry` = 164155;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164155 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164155, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Augur - World Loot Level 21'),
(164155, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Shadewell Murloc Augur - World Loot Level 22'),
(164155, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Shadewell Murloc Augur - Wool Cloth'),
(164155, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Shadewell Murloc Augur - Linen Cloth'),
(164155, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Shadewell Murloc Augur - Melon Juice'),
(164155, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Shadewell Murloc Augur - Silk Cloth'),
(164155, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Shadewell Murloc Augur - Ice Cold Milk'),
(164155, 1468, 0, 33.33, 0, 1, 0, 1, 1, 'Shadewell Murloc Augur - Murloc Fin'),
(164155, 730, 0, 36.13, 0, 1, 0, 1, 1, 'Shadewell Murloc Augur - Murloc Eye'),
(164155, 5523, 0, 36.6, 0, 1, 0, 1, 1, 'Shadewell Murloc Augur - Small Barnacled Clam'),
(164155, 6289, 0, 4.75, 0, 1, 0, 1, 3, 'Shadewell Murloc Augur - Raw Longjaw Mud Snapper');
-- Moldmoh (level 22-22, elemental)
UPDATE `creature_template` SET `lootid` = 164162 WHERE `entry` = 164162;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164162 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164162, 1, 1000022, 0, 0, 1, 5, 1, 1, 'Moldmoh - World Loot Level 22'),
(164162, 4606, 0, 4.62, 0, 1, 0, 1, 1, 'Moldmoh - Spongy Morel'),
(164162, 2453, 0, 2.5, 0, 1, 0, 1, 1, 'Moldmoh - Bruiseweed'),
(164162, 2452, 0, 1.67, 0, 1, 0, 1, 1, 'Moldmoh - Swiftthistle'),
(164162, 2450, 0, 2.24, 0, 1, 0, 1, 1, 'Moldmoh - Briarthorn'),
(164162, 2447, 0, 2.36, 0, 1, 0, 1, 1, 'Moldmoh - Peacebloom'),
(164162, 785, 0, 2.26, 0, 1, 0, 1, 1, 'Moldmoh - Mageroyal');
-- Guilded Fox (level 21-21, wolf)
UPDATE `creature_template` SET `lootid` = 164193 WHERE `entry` = 164193;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164193 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164193, 1, 1000021, 0, 0, 1, 5, 1, 1, 'Guilded Fox - World Loot Level 21'),
(164193, 5635, 0, 4.99, 0, 1, 0, 1, 1, 'Guilded Fox - Sharp Claw'),
(164193, 3301, 0, 24.99, 0, 1, 0, 1, 1, 'Guilded Fox - Sharp Canine'),
(164193, 3299, 0, 16.38, 0, 1, 0, 1, 1, 'Guilded Fox - Fractured Canine'),
(164193, 3402, 0, 22.25, 0, 1, 0, 1, 1, 'Guilded Fox - Soft Patch of Fur');
-- Hallow Wind Eagle (level 45-45, bird)
UPDATE `creature_template` SET `lootid` = 164194 WHERE `entry` = 164194;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164194 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164194, 1, 1000045, 0, 0, 1, 5, 1, 1, 'Hallow Wind Eagle - World Loot Level 45'),
(164194, 12207, 0, 46.07, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Giant Egg'),
(164194, 11418, 0, 29.45, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Hollow Wing Bone'),
(164194, 11417, 0, 9.62, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Feathery Wing'),
(164194, 8146, 0, 5.28, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Wicked Claw'),
(164194, 5829, 0, 30.19, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Razor-sharp Beak'),
(164194, 15420, 0, 44.41, 0, 1, 0, 1, 3, 'Hallow Wind Eagle - Ironfeather'),
(164194, 3404, 0, 37.73, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Buzzard Wing'),
(164194, 12037, 0, 38.49, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Mystery Meat');
-- Hallow Wind Eagle (level 20-21, bird)
UPDATE `creature_template` SET `lootid` = 164195 WHERE `entry` = 164195;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164195 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164195, 1, 1000020, 0, 0, 1, 5, 1, 1, 'Hallow Wind Eagle - World Loot Level 20'),
(164195, 2, 1000021, 0, 0, 1, 5, 1, 1, 'Hallow Wind Eagle - World Loot Level 21'),
(164195, 6889, 0, 60.58, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Small Egg'),
(164195, 4776, 0, 6.44, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Ruffled Feather'),
(164195, 4775, 0, 21.68, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Cracked Bill'),
(164195, 17056, 0, 30.06, 0, 1, 0, 1, 1, 'Hallow Wind Eagle - Light Feather');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164197 WHERE `entry` = 164197;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164197 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164197, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164197, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164197, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164197, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164197, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164197, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164197, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164198 WHERE `entry` = 164198;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164198 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164198, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164198, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164198, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164198, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164198, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164198, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164198, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164199 WHERE `entry` = 164199;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164199 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164199, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164199, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164199, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164199, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164199, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164199, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164199, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164200 WHERE `entry` = 164200;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164200 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164200, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164200, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164200, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164200, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164200, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164200, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164200, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164201 WHERE `entry` = 164201;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164201 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164201, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164201, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164201, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164201, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164201, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164201, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164201, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164202 WHERE `entry` = 164202;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164202 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164202, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164202, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164202, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164202, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164202, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164202, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164202, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164203 WHERE `entry` = 164203;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164203 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164203, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164203, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164203, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164203, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164203, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164203, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164203, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Hallow Wind Initiate (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164204 WHERE `entry` = 164204;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164204 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164204, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 19'),
(164204, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Hallow Wind Initiate - World Loot Level 20'),
(164204, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Hallow Wind Initiate - Linen Cloth'),
(164204, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Hallow Wind Initiate - Wool Cloth'),
(164204, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Ice Cold Milk'),
(164204, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Melon Juice'),
(164204, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Hallow Wind Initiate - Silk Cloth');
-- Grimepit Trogg (level 20-21, trogg)
UPDATE `creature_template` SET `lootid` = 164206 WHERE `entry` = 164206;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164206 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164206, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Grimepit Trogg - World Loot Level 20'),
(164206, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Grimepit Trogg - World Loot Level 21'),
(164206, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Grimepit Trogg - Linen Cloth'),
(164206, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Grimepit Trogg - Wool Cloth'),
(164206, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Grimepit Trogg - Ice Cold Milk'),
(164206, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Grimepit Trogg - Melon Juice'),
(164206, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Grimepit Trogg - Silk Cloth'),
(164206, 2838, 0, 0.6, 0, 1, 0, 1, 1, 'Grimepit Trogg - Heavy Stone');
-- Grime-King Augustus (level 19-20, humanoid)
UPDATE `creature_template` SET `lootid` = 164207 WHERE `entry` = 164207;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164207 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164207, 1, 1000119, 0, 0, 1, 5, 1, 1, 'Grime-King Augustus - World Loot Level 19'),
(164207, 2, 1000120, 0, 0, 1, 5, 1, 1, 'Grime-King Augustus - World Loot Level 20'),
(164207, 2589, 0, 16.58, 0, 1, 0, 1, 3, 'Grime-King Augustus - Linen Cloth'),
(164207, 2592, 0, 20.26, 0, 1, 0, 1, 2, 'Grime-King Augustus - Wool Cloth'),
(164207, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Grime-King Augustus - Ice Cold Milk'),
(164207, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Grime-King Augustus - Melon Juice'),
(164207, 4306, 0, 4.92, 0, 1, 0, 1, 1, 'Grime-King Augustus - Silk Cloth');
-- Petal Prowler (level 22-23, elemental)
UPDATE `creature_template` SET `lootid` = 164223 WHERE `entry` = 164223;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164223 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164223, 1, 1000022, 0, 0, 1, 5, 1, 1, 'Petal Prowler - World Loot Level 22'),
(164223, 2, 1000023, 0, 0, 1, 5, 1, 1, 'Petal Prowler - World Loot Level 23'),
(164223, 4606, 0, 4.62, 0, 1, 0, 1, 1, 'Petal Prowler - Spongy Morel'),
(164223, 2453, 0, 2.5, 0, 1, 0, 1, 1, 'Petal Prowler - Bruiseweed'),
(164223, 2452, 0, 1.67, 0, 1, 0, 1, 1, 'Petal Prowler - Swiftthistle'),
(164223, 2450, 0, 2.24, 0, 1, 0, 1, 1, 'Petal Prowler - Briarthorn'),
(164223, 2447, 0, 2.36, 0, 1, 0, 1, 1, 'Petal Prowler - Peacebloom'),
(164223, 785, 0, 2.26, 0, 1, 0, 1, 1, 'Petal Prowler - Mageroyal');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164226 WHERE `entry` = 164226;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164226 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164226, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164226, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164226, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164226, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164226, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164226, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164226, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164227 WHERE `entry` = 164227;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164227 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164227, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164227, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164227, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164227, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164227, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164227, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164227, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164228 WHERE `entry` = 164228;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164228 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164228, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164228, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164228, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164228, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164228, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164228, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164228, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164229 WHERE `entry` = 164229;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164229 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164229, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164229, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164229, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164229, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164229, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164229, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164229, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164230 WHERE `entry` = 164230;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164230 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164230, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164230, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164230, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164230, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164230, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164230, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164230, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164231 WHERE `entry` = 164231;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164231 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164231, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164231, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164231, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164231, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164231, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164231, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164231, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164232 WHERE `entry` = 164232;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164232 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164232, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164232, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164232, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164232, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164232, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164232, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164232, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Ealdmaine Aspirant (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164233 WHERE `entry` = 164233;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164233 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164233, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 21'),
(164233, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Ealdmaine Aspirant - World Loot Level 22'),
(164233, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Ealdmaine Aspirant - Wool Cloth'),
(164233, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Ealdmaine Aspirant - Linen Cloth'),
(164233, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Melon Juice'),
(164233, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Silk Cloth'),
(164233, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Ealdmaine Aspirant - Ice Cold Milk');
-- Shadewell Kobold (level 21-22, kobold)
UPDATE `creature_template` SET `lootid` = 164237 WHERE `entry` = 164237;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164237 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164237, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Shadewell Kobold - World Loot Level 21'),
(164237, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Shadewell Kobold - World Loot Level 22'),
(164237, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Shadewell Kobold - Wool Cloth'),
(164237, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Shadewell Kobold - Linen Cloth'),
(164237, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Shadewell Kobold - Melon Juice'),
(164237, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Shadewell Kobold - Silk Cloth'),
(164237, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Shadewell Kobold - Ice Cold Milk');
-- Rothfuss (level 22-23, humanoid)
UPDATE `creature_template` SET `lootid` = 164238 WHERE `entry` = 164238;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164238 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164238, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Rothfuss - World Loot Level 22'),
(164238, 2, 1000123, 0, 0, 1, 5, 1, 1, 'Rothfuss - World Loot Level 23'),
(164238, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Rothfuss - Wool Cloth'),
(164238, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Rothfuss - Linen Cloth'),
(164238, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Rothfuss - Melon Juice'),
(164238, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Rothfuss - Silk Cloth'),
(164238, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Rothfuss - Ice Cold Milk');
-- Blackrock Besieger (level 22-23, orc)
UPDATE `creature_template` SET `lootid` = 164247 WHERE `entry` = 164247;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164247 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164247, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Blackrock Besieger - World Loot Level 22'),
(164247, 2, 1000123, 0, 0, 1, 5, 1, 1, 'Blackrock Besieger - World Loot Level 23'),
(164247, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Blackrock Besieger - Wool Cloth'),
(164247, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Blackrock Besieger - Linen Cloth'),
(164247, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Blackrock Besieger - Melon Juice'),
(164247, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Blackrock Besieger - Silk Cloth'),
(164247, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Blackrock Besieger - Ice Cold Milk');
-- Blackrock Orc (level 22-23, orc)
UPDATE `creature_template` SET `lootid` = 164253 WHERE `entry` = 164253;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164253 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164253, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Blackrock Orc - World Loot Level 22'),
(164253, 2, 1000123, 0, 0, 1, 5, 1, 1, 'Blackrock Orc - World Loot Level 23'),
(164253, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Blackrock Orc - Wool Cloth'),
(164253, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Blackrock Orc - Linen Cloth'),
(164253, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Blackrock Orc - Melon Juice'),
(164253, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Blackrock Orc - Silk Cloth'),
(164253, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Blackrock Orc - Ice Cold Milk');
-- Butcher Eigor (level 23-24, humanoid)
UPDATE `creature_template` SET `lootid` = 164265 WHERE `entry` = 164265;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164265 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164265, 1, 1000123, 0, 0, 1, 5, 1, 1, 'Butcher Eigor - World Loot Level 23'),
(164265, 2, 1000124, 0, 0, 1, 5, 1, 1, 'Butcher Eigor - World Loot Level 24'),
(164265, 2592, 0, 19.14, 0, 1, 0, 1, 2, 'Butcher Eigor - Wool Cloth'),
(164265, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Butcher Eigor - Melon Juice'),
(164265, 4306, 0, 5.24, 0, 1, 0, 1, 2, 'Butcher Eigor - Silk Cloth'),
(164265, 2589, 0, 13.17, 0, 1, 0, 1, 3, 'Butcher Eigor - Linen Cloth');
-- Karegor Grimfang (level 56-56, humanoid)
UPDATE `creature_template` SET `lootid` = 164266 WHERE `entry` = 164266;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164266 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164266, 1, 1000156, 0, 0, 1, 5, 1, 1, 'Karegor Grimfang - World Loot Level 56'),
(164266, 14047, 0, 30.36, 0, 1, 0, 1, 4, 'Karegor Grimfang - Runecloth'),
(164266, 8766, 0, 2.57, 0, 1, 0, 1, 1, 'Karegor Grimfang - Morning Glory Dew'),
(164266, 8952, 0, 5.06, 0, 1, 0, 1, 1, 'Karegor Grimfang - Roasted Quail');
-- Blackrock Champion Kurgan (level 23-24, orc)
UPDATE `creature_template` SET `lootid` = 164267 WHERE `entry` = 164267;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164267 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164267, 1, 1000123, 0, 0, 1, 5, 1, 1, 'Blackrock Champion Kurgan - World Loot Level 23'),
(164267, 2, 1000124, 0, 0, 1, 5, 1, 1, 'Blackrock Champion Kurgan - World Loot Level 24'),
(164267, 2592, 0, 19.14, 0, 1, 0, 1, 2, 'Blackrock Champion Kurgan - Wool Cloth'),
(164267, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Blackrock Champion Kurgan - Melon Juice'),
(164267, 4306, 0, 5.24, 0, 1, 0, 1, 2, 'Blackrock Champion Kurgan - Silk Cloth'),
(164267, 2589, 0, 13.17, 0, 1, 0, 1, 3, 'Blackrock Champion Kurgan - Linen Cloth');
-- Kerebor Spy (level 23-24, humanoid)
UPDATE `creature_template` SET `lootid` = 164269 WHERE `entry` = 164269;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164269 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164269, 1, 1000123, 0, 0, 1, 5, 1, 1, 'Kerebor Spy - World Loot Level 23'),
(164269, 2, 1000124, 0, 0, 1, 5, 1, 1, 'Kerebor Spy - World Loot Level 24'),
(164269, 2592, 0, 19.14, 0, 1, 0, 1, 2, 'Kerebor Spy - Wool Cloth'),
(164269, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Kerebor Spy - Melon Juice'),
(164269, 4306, 0, 5.24, 0, 1, 0, 1, 2, 'Kerebor Spy - Silk Cloth'),
(164269, 2589, 0, 13.17, 0, 1, 0, 1, 3, 'Kerebor Spy - Linen Cloth');
-- Kerebor Infiltrator (level 23-24, humanoid)
UPDATE `creature_template` SET `lootid` = 164270 WHERE `entry` = 164270;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164270 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164270, 1, 1000123, 0, 0, 1, 5, 1, 1, 'Kerebor Infiltrator - World Loot Level 23'),
(164270, 2, 1000124, 0, 0, 1, 5, 1, 1, 'Kerebor Infiltrator - World Loot Level 24'),
(164270, 2592, 0, 19.14, 0, 1, 0, 1, 2, 'Kerebor Infiltrator - Wool Cloth'),
(164270, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Kerebor Infiltrator - Melon Juice'),
(164270, 4306, 0, 5.24, 0, 1, 0, 1, 2, 'Kerebor Infiltrator - Silk Cloth'),
(164270, 2589, 0, 13.17, 0, 1, 0, 1, 3, 'Kerebor Infiltrator - Linen Cloth');
-- Shadowburn Prospector (level 21-22, dwarf)
UPDATE `creature_template` SET `lootid` = 164274 WHERE `entry` = 164274;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164274 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164274, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Shadowburn Prospector - World Loot Level 21'),
(164274, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Shadowburn Prospector - World Loot Level 22'),
(164274, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Shadowburn Prospector - Wool Cloth'),
(164274, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Shadowburn Prospector - Linen Cloth'),
(164274, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Shadowburn Prospector - Melon Juice'),
(164274, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Shadowburn Prospector - Silk Cloth'),
(164274, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Shadowburn Prospector - Ice Cold Milk');
-- Captain Thorga Darkanvil (level 21-22, dwarf)
UPDATE `creature_template` SET `lootid` = 164275 WHERE `entry` = 164275;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164275 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164275, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Captain Thorga Darkanvil - World Loot Level 21'),
(164275, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Captain Thorga Darkanvil - World Loot Level 22'),
(164275, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Captain Thorga Darkanvil - Wool Cloth'),
(164275, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Captain Thorga Darkanvil - Linen Cloth'),
(164275, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Captain Thorga Darkanvil - Melon Juice'),
(164275, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Captain Thorga Darkanvil - Silk Cloth'),
(164275, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Captain Thorga Darkanvil - Ice Cold Milk');
-- Gilded Treant (level 29-30, treant)
UPDATE `creature_template` SET `lootid` = 164300 WHERE `entry` = 164300;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164300 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164300, 1, 1000029, 0, 0, 1, 5, 1, 1, 'Gilded Treant - World Loot Level 29'),
(164300, 2, 1000030, 0, 0, 1, 5, 1, 1, 'Gilded Treant - World Loot Level 30'),
(164300, 4606, 0, 4.61, 0, 1, 0, 1, 1, 'Gilded Treant - Spongy Morel'),
(164300, 1205, 0, 2.46, 0, 1, 0, 1, 1, 'Gilded Treant - Melon Juice'),
(164300, 2453, 0, 2.4, 0, 1, 0, 1, 1, 'Gilded Treant - Bruiseweed'),
(164300, 2452, 0, 1.44, 0, 1, 0, 1, 1, 'Gilded Treant - Swiftthistle'),
(164300, 2450, 0, 2.24, 0, 1, 0, 1, 1, 'Gilded Treant - Briarthorn'),
(164300, 2449, 0, 2.34, 0, 1, 0, 1, 1, 'Gilded Treant - Earthroot');
-- Furious Gilded Treant (level 29-30, treant)
UPDATE `creature_template` SET `lootid` = 164301 WHERE `entry` = 164301;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164301 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164301, 1, 1000029, 0, 0, 1, 5, 1, 1, 'Furious Gilded Treant - World Loot Level 29'),
(164301, 2, 1000030, 0, 0, 1, 5, 1, 1, 'Furious Gilded Treant - World Loot Level 30'),
(164301, 4606, 0, 4.61, 0, 1, 0, 1, 1, 'Furious Gilded Treant - Spongy Morel'),
(164301, 1205, 0, 2.46, 0, 1, 0, 1, 1, 'Furious Gilded Treant - Melon Juice'),
(164301, 2453, 0, 2.4, 0, 1, 0, 1, 1, 'Furious Gilded Treant - Bruiseweed'),
(164301, 2452, 0, 1.44, 0, 1, 0, 1, 1, 'Furious Gilded Treant - Swiftthistle'),
(164301, 2450, 0, 2.24, 0, 1, 0, 1, 1, 'Furious Gilded Treant - Briarthorn'),
(164301, 2449, 0, 2.34, 0, 1, 0, 1, 1, 'Furious Gilded Treant - Earthroot');
-- Blood Elf Knight (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164307 WHERE `entry` = 164307;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164307 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164307, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Blood Elf Knight - World Loot Level 21'),
(164307, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Blood Elf Knight - World Loot Level 22'),
(164307, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Blood Elf Knight - Wool Cloth'),
(164307, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Blood Elf Knight - Linen Cloth'),
(164307, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Blood Elf Knight - Melon Juice'),
(164307, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Blood Elf Knight - Silk Cloth'),
(164307, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Blood Elf Knight - Ice Cold Milk');
-- Blood Elf Magister (level 29-30, humanoid)
UPDATE `creature_template` SET `lootid` = 164308 WHERE `entry` = 164308;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164308 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164308, 1, 1000129, 0, 0, 1, 5, 1, 1, 'Blood Elf Magister - World Loot Level 29'),
(164308, 2, 1000130, 0, 0, 1, 5, 1, 1, 'Blood Elf Magister - World Loot Level 30'),
(164308, 4306, 0, 24.37, 0, 1, 0, 1, 2, 'Blood Elf Magister - Silk Cloth'),
(164308, 2592, 0, 9.53, 0, 1, 0, 1, 3, 'Blood Elf Magister - Wool Cloth'),
(164308, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Blood Elf Magister - Melon Juice'),
(164308, 1708, 0, 2.36, 0, 1, 0, 1, 1, 'Blood Elf Magister - Sweet Nectar');
-- The Family Zealot (level 29-30, humanoid)
UPDATE `creature_template` SET `lootid` = 164310 WHERE `entry` = 164310;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164310 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164310, 1, 1000129, 0, 0, 1, 5, 1, 1, 'The Family Zealot - World Loot Level 29'),
(164310, 2, 1000130, 0, 0, 1, 5, 1, 1, 'The Family Zealot - World Loot Level 30'),
(164310, 4306, 0, 24.37, 0, 1, 0, 1, 2, 'The Family Zealot - Silk Cloth'),
(164310, 2592, 0, 9.53, 0, 1, 0, 1, 3, 'The Family Zealot - Wool Cloth'),
(164310, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'The Family Zealot - Melon Juice'),
(164310, 1708, 0, 2.36, 0, 1, 0, 1, 1, 'The Family Zealot - Sweet Nectar');
-- The Family Cultist (level 29-30, humanoid)
UPDATE `creature_template` SET `lootid` = 164312 WHERE `entry` = 164312;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164312 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164312, 1, 1000129, 0, 0, 1, 5, 1, 1, 'The Family Cultist - World Loot Level 29'),
(164312, 2, 1000130, 0, 0, 1, 5, 1, 1, 'The Family Cultist - World Loot Level 30'),
(164312, 4306, 0, 24.37, 0, 1, 0, 1, 2, 'The Family Cultist - Silk Cloth'),
(164312, 2592, 0, 9.53, 0, 1, 0, 1, 3, 'The Family Cultist - Wool Cloth'),
(164312, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'The Family Cultist - Melon Juice'),
(164312, 1708, 0, 2.36, 0, 1, 0, 1, 1, 'The Family Cultist - Sweet Nectar');
-- Reanimated Devotee (level 21-22, undead)
UPDATE `creature_template` SET `lootid` = 164313 WHERE `entry` = 164313;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164313 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164313, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Reanimated Devotee - World Loot Level 21'),
(164313, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Reanimated Devotee - World Loot Level 22'),
(164313, 2592, 0, 19.1, 0, 1, 0, 1, 2, 'Reanimated Devotee - Wool Cloth'),
(164313, 2589, 0, 18.63, 0, 1, 0, 1, 3, 'Reanimated Devotee - Linen Cloth'),
(164313, 1179, 0, 2.67, 0, 1, 0, 1, 1, 'Reanimated Devotee - Ice Cold Milk'),
(164313, 4605, 0, 5.07, 0, 1, 0, 1, 1, 'Reanimated Devotee - Red-speckled Mushroom'),
(164313, 4606, 0, 4.83, 0, 1, 0, 1, 1, 'Reanimated Devotee - Spongy Morel'),
(164313, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Reanimated Devotee - Melon Juice');
-- Kharadol Ealdir (level 29-30, humanoid)
UPDATE `creature_template` SET `lootid` = 164317 WHERE `entry` = 164317;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164317 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164317, 1, 1000129, 0, 0, 1, 5, 1, 1, 'Kharadol Ealdir - World Loot Level 29'),
(164317, 2, 1000130, 0, 0, 1, 5, 1, 1, 'Kharadol Ealdir - World Loot Level 30'),
(164317, 4306, 0, 24.37, 0, 1, 0, 1, 2, 'Kharadol Ealdir - Silk Cloth'),
(164317, 2592, 0, 9.53, 0, 1, 0, 1, 3, 'Kharadol Ealdir - Wool Cloth'),
(164317, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Kharadol Ealdir - Melon Juice'),
(164317, 1708, 0, 2.36, 0, 1, 0, 1, 1, 'Kharadol Ealdir - Sweet Nectar');
-- Shadowed (level 27-28, elemental)
UPDATE `creature_template` SET `lootid` = 164328 WHERE `entry` = 164328;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164328 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164328, 1, 1000027, 0, 0, 1, 5, 1, 1, 'Shadowed - World Loot Level 27'),
(164328, 2, 1000028, 0, 0, 1, 5, 1, 1, 'Shadowed - World Loot Level 28');
-- Braicag Ealdir (level 27-28, humanoid)
UPDATE `creature_template` SET `lootid` = 164341 WHERE `entry` = 164341;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164341 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164341, 1, 1000127, 0, 0, 1, 5, 1, 1, 'Braicag Ealdir - World Loot Level 27'),
(164341, 2, 1000128, 0, 0, 1, 5, 1, 1, 'Braicag Ealdir - World Loot Level 28'),
(164341, 2592, 0, 10.16, 0, 1, 0, 1, 2, 'Braicag Ealdir - Wool Cloth'),
(164341, 4306, 0, 22.98, 0, 1, 0, 1, 2, 'Braicag Ealdir - Silk Cloth'),
(164341, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Braicag Ealdir - Melon Juice'),
(164341, 2589, 0, 12.54, 0, 1, 0, 1, 3, 'Braicag Ealdir - Linen Cloth');
-- Chieftain Saidarn (level 28-29, humanoid)
UPDATE `creature_template` SET `lootid` = 164342 WHERE `entry` = 164342;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164342 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164342, 1, 1000128, 0, 0, 1, 5, 1, 1, 'Chieftain Saidarn - World Loot Level 28'),
(164342, 2, 1000129, 0, 0, 1, 5, 1, 1, 'Chieftain Saidarn - World Loot Level 29'),
(164342, 2592, 0, 9.89, 0, 1, 0, 1, 2, 'Chieftain Saidarn - Wool Cloth'),
(164342, 4306, 0, 23.68, 0, 1, 0, 1, 2, 'Chieftain Saidarn - Silk Cloth'),
(164342, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Chieftain Saidarn - Melon Juice');
-- Runic Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164343 WHERE `entry` = 164343;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164343 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164343, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Runic Ealdir - World Loot Level 21'),
(164343, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Runic Ealdir - World Loot Level 22'),
(164343, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Runic Ealdir - Wool Cloth'),
(164343, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Runic Ealdir - Linen Cloth'),
(164343, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Runic Ealdir - Melon Juice'),
(164343, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Runic Ealdir - Silk Cloth'),
(164343, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Runic Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164348 WHERE `entry` = 164348;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164348 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164348, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164348, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164348, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164348, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164348, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164348, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164348, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164349 WHERE `entry` = 164349;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164349 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164349, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164349, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164349, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164349, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164349, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164349, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164349, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164350 WHERE `entry` = 164350;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164350 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164350, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164350, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164350, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164350, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164350, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164350, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164350, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164351 WHERE `entry` = 164351;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164351 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164351, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164351, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164351, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164351, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164351, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164351, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164351, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164352 WHERE `entry` = 164352;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164352 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164352, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164352, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164352, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164352, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164352, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164352, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164352, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164353 WHERE `entry` = 164353;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164353 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164353, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164353, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164353, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164353, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164353, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164353, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164353, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Baile Escada Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164354 WHERE `entry` = 164354;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164354 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164354, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 21'),
(164354, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Baile Escada Ealdir - World Loot Level 22'),
(164354, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Baile Escada Ealdir - Wool Cloth'),
(164354, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Baile Escada Ealdir - Linen Cloth'),
(164354, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Melon Juice'),
(164354, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Silk Cloth'),
(164354, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Baile Escada Ealdir - Ice Cold Milk');
-- Hushed Ealdir (level 28-29, humanoid)
UPDATE `creature_template` SET `lootid` = 164356 WHERE `entry` = 164356;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164356 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164356, 1, 1000128, 0, 0, 1, 5, 1, 1, 'Hushed Ealdir - World Loot Level 28'),
(164356, 2, 1000129, 0, 0, 1, 5, 1, 1, 'Hushed Ealdir - World Loot Level 29'),
(164356, 2592, 0, 9.89, 0, 1, 0, 1, 2, 'Hushed Ealdir - Wool Cloth'),
(164356, 4306, 0, 23.68, 0, 1, 0, 1, 2, 'Hushed Ealdir - Silk Cloth'),
(164356, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Hushed Ealdir - Melon Juice');
-- Shadowarden (level 19-20, elemental)
UPDATE `creature_template` SET `lootid` = 164358 WHERE `entry` = 164358;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164358 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164358, 1, 1000019, 0, 0, 1, 5, 1, 1, 'Shadowarden - World Loot Level 19'),
(164358, 2, 1000020, 0, 0, 1, 5, 1, 1, 'Shadowarden - World Loot Level 20');
-- Horned One (level 20-21, beast)
UPDATE `creature_template` SET `lootid` = 164373 WHERE `entry` = 164373;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164373 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164373, 1, 1000020, 0, 0, 1, 5, 1, 1, 'Horned One - World Loot Level 20'),
(164373, 2, 1000021, 0, 0, 1, 5, 1, 1, 'Horned One - World Loot Level 21'),
(164373, 5635, 0, 4.57, 0, 1, 0, 1, 1, 'Horned One - Sharp Claw');
-- Frosty Crab (level 22-23, crab)
UPDATE `creature_template` SET `lootid` = 164394 WHERE `entry` = 164394;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164394 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164394, 1, 1000022, 0, 0, 1, 5, 1, 1, 'Frosty Crab - World Loot Level 22'),
(164394, 2, 1000023, 0, 0, 1, 5, 1, 1, 'Frosty Crab - World Loot Level 23'),
(164394, 5635, 0, 5.03, 0, 1, 0, 1, 1, 'Frosty Crab - Sharp Claw'),
(164394, 2675, 0, 39.97, 0, 1, 0, 1, 1, 'Frosty Crab - Crawler Claw'),
(164394, 2674, 0, 39.61, 0, 1, 0, 1, 1, 'Frosty Crab - Crawler Meat'),
(164394, 4874, 0, 22.26, 0, 1, 0, 1, 1, 'Frosty Crab - Clean Fishbones'),
(164394, 5523, 0, 39.94, 0, 1, 0, 1, 1, 'Frosty Crab - Small Barnacled Clam');
-- Antennasplitter Trogg (level 22-23, trogg)
UPDATE `creature_template` SET `lootid` = 164398 WHERE `entry` = 164398;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164398 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164398, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Antennasplitter Trogg - World Loot Level 22'),
(164398, 2, 1000123, 0, 0, 1, 5, 1, 1, 'Antennasplitter Trogg - World Loot Level 23'),
(164398, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Antennasplitter Trogg - Wool Cloth'),
(164398, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Antennasplitter Trogg - Linen Cloth'),
(164398, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Antennasplitter Trogg - Melon Juice'),
(164398, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Antennasplitter Trogg - Silk Cloth'),
(164398, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Antennasplitter Trogg - Ice Cold Milk'),
(164398, 2838, 0, 0.6, 0, 1, 0, 1, 1, 'Antennasplitter Trogg - Heavy Stone');
-- Ealdfrost Bear (level 20-21, bear)
UPDATE `creature_template` SET `lootid` = 164418 WHERE `entry` = 164418;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164418 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164418, 1, 1000020, 0, 0, 1, 5, 1, 1, 'Ealdfrost Bear - World Loot Level 20'),
(164418, 2, 1000021, 0, 0, 1, 5, 1, 1, 'Ealdfrost Bear - World Loot Level 21'),
(164418, 11406, 0, 30.73, 0, 1, 0, 1, 1, 'Ealdfrost Bear - Rotting Bear Carcass'),
(164418, 2940, 0, 31.18, 0, 1, 0, 1, 1, 'Ealdfrost Bear - Bloody Bear Paw'),
(164418, 5635, 0, 3.58, 0, 1, 0, 1, 1, 'Ealdfrost Bear - Sharp Claw'),
(164418, 3173, 0, 38.0, 0, 1, 0, 1, 1, 'Ealdfrost Bear - Bear Meat'),
(164418, 3170, 0, 29.37, 0, 1, 0, 1, 1, 'Ealdfrost Bear - Large Bear Tooth'),
(164418, 3169, 0, 29.23, 0, 1, 0, 1, 1, 'Ealdfrost Bear - Chipped Bear Tooth');
-- Ealdfrost Saber (level 20-21, cat)
UPDATE `creature_template` SET `lootid` = 164419 WHERE `entry` = 164419;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164419 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164419, 1, 1000020, 0, 0, 1, 5, 1, 1, 'Ealdfrost Saber - World Loot Level 20'),
(164419, 2, 1000021, 0, 0, 1, 5, 1, 1, 'Ealdfrost Saber - World Loot Level 21'),
(164419, 5635, 0, 4.23, 0, 1, 0, 1, 1, 'Ealdfrost Saber - Sharp Claw'),
(164419, 5135, 0, 31.01, 0, 1, 0, 1, 1, 'Ealdfrost Saber - Thin Black Claw'),
(164419, 5136, 0, 54.18, 0, 1, 0, 1, 1, 'Ealdfrost Saber - Torn Furry Ear'),
(164419, 4813, 0, 16.02, 0, 1, 0, 1, 1, 'Ealdfrost Saber - Small Leather Collar'),
(164419, 4814, 0, 61.71, 0, 1, 0, 1, 1, 'Ealdfrost Saber - Discolored Fang'),
(164419, 5637, 0, 4.09, 0, 1, 0, 1, 1, 'Ealdfrost Saber - Large Fang');
-- Quillscale Murloc (level 27-28, murloc)
UPDATE `creature_template` SET `lootid` = 164429 WHERE `entry` = 164429;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164429 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164429, 1, 1000127, 0, 0, 1, 5, 1, 1, 'Quillscale Murloc - World Loot Level 27'),
(164429, 2, 1000128, 0, 0, 1, 5, 1, 1, 'Quillscale Murloc - World Loot Level 28'),
(164429, 2592, 0, 10.16, 0, 1, 0, 1, 2, 'Quillscale Murloc - Wool Cloth'),
(164429, 4306, 0, 22.98, 0, 1, 0, 1, 2, 'Quillscale Murloc - Silk Cloth'),
(164429, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Quillscale Murloc - Melon Juice'),
(164429, 2589, 0, 12.54, 0, 1, 0, 1, 3, 'Quillscale Murloc - Linen Cloth'),
(164429, 1468, 0, 31.66, 0, 1, 0, 1, 1, 'Quillscale Murloc - Murloc Fin'),
(164429, 730, 0, 36.25, 0, 1, 0, 1, 1, 'Quillscale Murloc - Murloc Eye'),
(164429, 5523, 0, 37.0, 0, 1, 0, 1, 1, 'Quillscale Murloc - Small Barnacled Clam'),
(164429, 6289, 0, 4.71, 0, 1, 0, 1, 3, 'Quillscale Murloc - Raw Longjaw Mud Snapper');
-- Whimsical Quillscale Murloc (level 27-28, murloc)
UPDATE `creature_template` SET `lootid` = 164430 WHERE `entry` = 164430;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164430 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164430, 1, 1000127, 0, 0, 1, 5, 1, 1, 'Whimsical Quillscale Murloc - World Loot Level 27'),
(164430, 2, 1000128, 0, 0, 1, 5, 1, 1, 'Whimsical Quillscale Murloc - World Loot Level 28'),
(164430, 2592, 0, 10.16, 0, 1, 0, 1, 2, 'Whimsical Quillscale Murloc - Wool Cloth'),
(164430, 4306, 0, 22.98, 0, 1, 0, 1, 2, 'Whimsical Quillscale Murloc - Silk Cloth'),
(164430, 1205, 0, 2.42, 0, 1, 0, 1, 1, 'Whimsical Quillscale Murloc - Melon Juice'),
(164430, 2589, 0, 12.54, 0, 1, 0, 1, 3, 'Whimsical Quillscale Murloc - Linen Cloth'),
(164430, 1468, 0, 31.66, 0, 1, 0, 1, 1, 'Whimsical Quillscale Murloc - Murloc Fin'),
(164430, 730, 0, 36.25, 0, 1, 0, 1, 1, 'Whimsical Quillscale Murloc - Murloc Eye'),
(164430, 5523, 0, 37.0, 0, 1, 0, 1, 1, 'Whimsical Quillscale Murloc - Small Barnacled Clam'),
(164430, 6289, 0, 4.71, 0, 1, 0, 1, 3, 'Whimsical Quillscale Murloc - Raw Longjaw Mud Snapper');
-- Bonesurper Troll (level 23-23, troll)
UPDATE `creature_template` SET `lootid` = 164431 WHERE `entry` = 164431;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164431 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164431, 1, 1000123, 0, 0, 1, 5, 1, 1, 'Bonesurper Troll - World Loot Level 23'),
(164431, 2592, 0, 19.14, 0, 1, 0, 1, 2, 'Bonesurper Troll - Wool Cloth'),
(164431, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Bonesurper Troll - Melon Juice'),
(164431, 4306, 0, 5.24, 0, 1, 0, 1, 2, 'Bonesurper Troll - Silk Cloth'),
(164431, 2589, 0, 13.17, 0, 1, 0, 1, 3, 'Bonesurper Troll - Linen Cloth');
-- Necrotic Witch Altamira (level 23-23, humanoid)
UPDATE `creature_template` SET `lootid` = 164432 WHERE `entry` = 164432;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164432 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164432, 1, 1000123, 0, 0, 1, 5, 1, 1, 'Necrotic Witch Altamira - World Loot Level 23'),
(164432, 2592, 0, 19.14, 0, 1, 0, 1, 2, 'Necrotic Witch Altamira - Wool Cloth'),
(164432, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Necrotic Witch Altamira - Melon Juice'),
(164432, 4306, 0, 5.24, 0, 1, 0, 1, 2, 'Necrotic Witch Altamira - Silk Cloth'),
(164432, 2589, 0, 13.17, 0, 1, 0, 1, 3, 'Necrotic Witch Altamira - Linen Cloth');
-- Frostmane Raider (level 25-26, troll)
UPDATE `creature_template` SET `lootid` = 164438 WHERE `entry` = 164438;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164438 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164438, 1, 1000125, 0, 0, 1, 5, 1, 1, 'Frostmane Raider - World Loot Level 25'),
(164438, 2, 1000126, 0, 0, 1, 5, 1, 1, 'Frostmane Raider - World Loot Level 26'),
(164438, 2592, 0, 17.0, 0, 1, 0, 1, 2, 'Frostmane Raider - Wool Cloth'),
(164438, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Frostmane Raider - Melon Juice'),
(164438, 4306, 0, 20.02, 0, 1, 0, 1, 2, 'Frostmane Raider - Silk Cloth'),
(164438, 2589, 0, 12.88, 0, 1, 0, 1, 3, 'Frostmane Raider - Linen Cloth'),
(164438, 1520, 0, 29.63, 0, 1, 0, 1, 1, 'Frostmane Raider - Troll Sweat'),
(164438, 8151, 0, 9.56, 0, 1, 0, 1, 1, 'Frostmane Raider - Flask of Mojo');
-- Frostmane Raider (level 21-22, troll)
UPDATE `creature_template` SET `lootid` = 164440 WHERE `entry` = 164440;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164440 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164440, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Frostmane Raider - World Loot Level 21'),
(164440, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Frostmane Raider - World Loot Level 22'),
(164440, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Frostmane Raider - Wool Cloth'),
(164440, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Frostmane Raider - Linen Cloth'),
(164440, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Frostmane Raider - Melon Juice'),
(164440, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Frostmane Raider - Silk Cloth'),
(164440, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Frostmane Raider - Ice Cold Milk');
-- Horde Collaborator (level 24-25, humanoid)
UPDATE `creature_template` SET `lootid` = 164443 WHERE `entry` = 164443;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164443 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164443, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Horde Collaborator - World Loot Level 24'),
(164443, 2, 1000125, 0, 0, 1, 5, 1, 1, 'Horde Collaborator - World Loot Level 25'),
(164443, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Horde Collaborator - Wool Cloth'),
(164443, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Horde Collaborator - Melon Juice'),
(164443, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Horde Collaborator - Silk Cloth'),
(164443, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Horde Collaborator - Linen Cloth');
-- Horde Collaborator (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164444 WHERE `entry` = 164444;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164444 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164444, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Horde Collaborator - World Loot Level 21'),
(164444, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Horde Collaborator - World Loot Level 22'),
(164444, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Horde Collaborator - Wool Cloth'),
(164444, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Horde Collaborator - Linen Cloth'),
(164444, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Horde Collaborator - Melon Juice'),
(164444, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Horde Collaborator - Silk Cloth'),
(164444, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Horde Collaborator - Ice Cold Milk');
-- Horde Collaborator (level 24-24, humanoid)
UPDATE `creature_template` SET `lootid` = 164445 WHERE `entry` = 164445;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164445 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164445, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Horde Collaborator - World Loot Level 24'),
(164445, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Horde Collaborator - Wool Cloth'),
(164445, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Horde Collaborator - Melon Juice'),
(164445, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Horde Collaborator - Silk Cloth'),
(164445, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Horde Collaborator - Linen Cloth');
-- Frostmane Soldier (level 24-25, troll)
UPDATE `creature_template` SET `lootid` = 164447 WHERE `entry` = 164447;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164447 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164447, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Frostmane Soldier - World Loot Level 24'),
(164447, 2, 1000125, 0, 0, 1, 5, 1, 1, 'Frostmane Soldier - World Loot Level 25'),
(164447, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Frostmane Soldier - Wool Cloth'),
(164447, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Soldier - Melon Juice'),
(164447, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Frostmane Soldier - Silk Cloth'),
(164447, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Frostmane Soldier - Linen Cloth'),
(164447, 1520, 0, 19.98, 0, 1, 0, 1, 1, 'Frostmane Soldier - Troll Sweat');
-- Sicklight Outrider (level 24-25, humanoid)
UPDATE `creature_template` SET `lootid` = 164449 WHERE `entry` = 164449;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164449 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164449, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Sicklight Outrider - World Loot Level 24'),
(164449, 2, 1000125, 0, 0, 1, 5, 1, 1, 'Sicklight Outrider - World Loot Level 25'),
(164449, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Sicklight Outrider - Wool Cloth'),
(164449, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Sicklight Outrider - Melon Juice'),
(164449, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Sicklight Outrider - Silk Cloth'),
(164449, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Sicklight Outrider - Linen Cloth');
-- Skulltaker Marauder (level 24-25, humanoid)
UPDATE `creature_template` SET `lootid` = 164459 WHERE `entry` = 164459;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164459 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164459, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Skulltaker Marauder - World Loot Level 24'),
(164459, 2, 1000125, 0, 0, 1, 5, 1, 1, 'Skulltaker Marauder - World Loot Level 25'),
(164459, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Skulltaker Marauder - Wool Cloth'),
(164459, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Skulltaker Marauder - Melon Juice'),
(164459, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Skulltaker Marauder - Silk Cloth'),
(164459, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Skulltaker Marauder - Linen Cloth');
-- Frost Elemental (level 24-25, elemental)
UPDATE `creature_template` SET `lootid` = 164461 WHERE `entry` = 164461;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164461 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164461, 1, 1000024, 0, 0, 1, 5, 1, 1, 'Frost Elemental - World Loot Level 24'),
(164461, 2, 1000025, 0, 0, 1, 5, 1, 1, 'Frost Elemental - World Loot Level 25');
-- Wild Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164495 WHERE `entry` = 164495;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164495 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164495, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Wild Ealdir - World Loot Level 21'),
(164495, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Wild Ealdir - World Loot Level 22'),
(164495, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Wild Ealdir - Wool Cloth'),
(164495, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Wild Ealdir - Linen Cloth'),
(164495, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Wild Ealdir - Melon Juice'),
(164495, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Wild Ealdir - Silk Cloth'),
(164495, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Wild Ealdir - Ice Cold Milk');
-- Wild Ealdir (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164496 WHERE `entry` = 164496;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164496 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164496, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Wild Ealdir - World Loot Level 21'),
(164496, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Wild Ealdir - World Loot Level 22'),
(164496, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Wild Ealdir - Wool Cloth'),
(164496, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Wild Ealdir - Linen Cloth'),
(164496, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Wild Ealdir - Melon Juice'),
(164496, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Wild Ealdir - Silk Cloth'),
(164496, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Wild Ealdir - Ice Cold Milk');
-- Scadeald Goat (level 19-20, beast)
UPDATE `creature_template` SET `lootid` = 164553 WHERE `entry` = 164553;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164553 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164553, 1, 1000019, 0, 0, 1, 5, 1, 1, 'Scadeald Goat - World Loot Level 19'),
(164553, 2, 1000020, 0, 0, 1, 5, 1, 1, 'Scadeald Goat - World Loot Level 20'),
(164553, 5120, 0, 8.2, 0, 1, 0, 1, 1, 'Scadeald Goat - Long Tail Hair'),
(164553, 5566, 0, 45.99, 0, 1, 0, 1, 1, 'Scadeald Goat - Broken Antler'),
(164553, 5471, 0, 42.43, 0, 1, 0, 1, 1, 'Scadeald Goat - Stag Meat'),
(164553, 5871, 0, 16.82, 0, 1, 0, 1, 1, 'Scadeald Goat - Large Hoof'),
(164553, 5119, 0, 22.42, 0, 1, 0, 1, 1, 'Scadeald Goat - Fine Loose Hair');
-- Frostmane Troll (level 20-21, troll)
UPDATE `creature_template` SET `lootid` = 164554 WHERE `entry` = 164554;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164554 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164554, 1, 1000120, 0, 0, 1, 5, 1, 1, 'Frostmane Troll - World Loot Level 20'),
(164554, 2, 1000121, 0, 0, 1, 5, 1, 1, 'Frostmane Troll - World Loot Level 21'),
(164554, 2589, 0, 14.78, 0, 1, 0, 1, 3, 'Frostmane Troll - Linen Cloth'),
(164554, 2592, 0, 20.0, 0, 1, 0, 1, 2, 'Frostmane Troll - Wool Cloth'),
(164554, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Frostmane Troll - Ice Cold Milk'),
(164554, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Troll - Melon Juice'),
(164554, 4306, 0, 5.0, 0, 1, 0, 1, 1, 'Frostmane Troll - Silk Cloth');
-- Blackrock Blacksmith (level 21-22, orc)
UPDATE `creature_template` SET `lootid` = 164559 WHERE `entry` = 164559;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164559 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164559, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Blackrock Blacksmith - World Loot Level 21'),
(164559, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Blackrock Blacksmith - World Loot Level 22'),
(164559, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'Blackrock Blacksmith - Wool Cloth'),
(164559, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'Blackrock Blacksmith - Linen Cloth'),
(164559, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Blackrock Blacksmith - Melon Juice'),
(164559, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'Blackrock Blacksmith - Silk Cloth'),
(164559, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'Blackrock Blacksmith - Ice Cold Milk');
-- The Family Fanatic (level 21-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164562 WHERE `entry` = 164562;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164562 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164562, 1, 1000121, 0, 0, 1, 5, 1, 1, 'The Family Fanatic - World Loot Level 21'),
(164562, 2, 1000122, 0, 0, 1, 5, 1, 1, 'The Family Fanatic - World Loot Level 22'),
(164562, 2592, 0, 19.87, 0, 1, 0, 1, 2, 'The Family Fanatic - Wool Cloth'),
(164562, 2589, 0, 13.91, 0, 1, 0, 1, 3, 'The Family Fanatic - Linen Cloth'),
(164562, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'The Family Fanatic - Melon Juice'),
(164562, 4306, 0, 5.02, 0, 1, 0, 1, 1, 'The Family Fanatic - Silk Cloth'),
(164562, 1179, 0, 2.41, 0, 1, 0, 1, 1, 'The Family Fanatic - Ice Cold Milk');
-- Frostmane Mystic (level 24-24, troll)
UPDATE `creature_template` SET `lootid` = 164567 WHERE `entry` = 164567;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164567 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164567, 1, 1000124, 0, 0, 1, 5, 1, 1, 'Frostmane Mystic - World Loot Level 24'),
(164567, 2592, 0, 18.7, 0, 1, 0, 1, 2, 'Frostmane Mystic - Wool Cloth'),
(164567, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Frostmane Mystic - Melon Juice'),
(164567, 4306, 0, 16.12, 0, 1, 0, 1, 2, 'Frostmane Mystic - Silk Cloth'),
(164567, 2589, 0, 13.0, 0, 1, 0, 1, 3, 'Frostmane Mystic - Linen Cloth'),
(164567, 1520, 0, 19.98, 0, 1, 0, 1, 1, 'Frostmane Mystic - Troll Sweat');
-- Cardinal Royce (level 22-22, undead)
UPDATE `creature_template` SET `lootid` = 164598 WHERE `entry` = 164598;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164598 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164598, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Cardinal Royce - World Loot Level 22'),
(164598, 2592, 0, 18.96, 0, 1, 0, 1, 2, 'Cardinal Royce - Wool Cloth'),
(164598, 2589, 0, 18.44, 0, 1, 0, 1, 3, 'Cardinal Royce - Linen Cloth'),
(164598, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Cardinal Royce - Melon Juice'),
(164598, 1179, 0, 2.67, 0, 1, 0, 1, 1, 'Cardinal Royce - Ice Cold Milk'),
(164598, 4306, 0, 13.75, 0, 1, 0, 1, 2, 'Cardinal Royce - Silk Cloth'),
(164598, 4606, 0, 4.82, 0, 1, 0, 1, 1, 'Cardinal Royce - Spongy Morel');
-- Sickly Slime (level 23-24, ooze)
UPDATE `creature_template` SET `lootid` = 164599 WHERE `entry` = 164599;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164599 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164599, 1, 1000023, 0, 0, 1, 5, 1, 1, 'Sickly Slime - World Loot Level 23'),
(164599, 2, 1000024, 0, 0, 1, 5, 1, 1, 'Sickly Slime - World Loot Level 24'),
(164599, 5635, 0, 5.07, 0, 1, 0, 1, 1, 'Sickly Slime - Sharp Claw'),
(164599, 3676, 0, 13.23, 0, 1, 0, 1, 2, 'Sickly Slime - Slimy Ichor'),
(164599, 3671, 0, 7.82, 0, 1, 0, 1, 2, 'Sickly Slime - Lifeless Skull'),
(164599, 3674, 0, 10.0, 0, 1, 0, 1, 2, 'Sickly Slime - Decomposed Boot'),
(164599, 3670, 0, 12.0, 0, 1, 0, 1, 2, 'Sickly Slime - Large Slimy Bone');
-- Hornhide Goat (level 17-18, beast)
UPDATE `creature_template` SET `lootid` = 164688 WHERE `entry` = 164688;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164688 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164688, 1, 1000017, 0, 0, 1, 5, 1, 1, 'Hornhide Goat - World Loot Level 17'),
(164688, 2, 1000018, 0, 0, 1, 5, 1, 1, 'Hornhide Goat - World Loot Level 18'),
(164688, 5120, 0, 34.48, 0, 1, 0, 1, 1, 'Hornhide Goat - Long Tail Hair'),
(164688, 5566, 0, 52.59, 0, 1, 0, 1, 1, 'Hornhide Goat - Broken Antler'),
(164688, 5471, 0, 49.29, 0, 1, 0, 1, 1, 'Hornhide Goat - Stag Meat'),
(164688, 5871, 0, 19.74, 0, 1, 0, 1, 1, 'Hornhide Goat - Large Hoof'),
(164688, 5119, 0, 22.42, 0, 1, 0, 1, 1, 'Hornhide Goat - Fine Loose Hair');
-- Ealdir Ambusher (level 18-19, humanoid)
UPDATE `creature_template` SET `lootid` = 164926 WHERE `entry` = 164926;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164926 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164926, 1, 1000118, 0, 0, 1, 5, 1, 1, 'Ealdir Ambusher - World Loot Level 18'),
(164926, 2, 1000119, 0, 0, 1, 5, 1, 1, 'Ealdir Ambusher - World Loot Level 19'),
(164926, 2589, 0, 17.94, 0, 1, 0, 1, 3, 'Ealdir Ambusher - Linen Cloth'),
(164926, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Ealdir Ambusher - Ice Cold Milk'),
(164926, 2592, 0, 20.19, 0, 1, 0, 1, 2, 'Ealdir Ambusher - Wool Cloth'),
(164926, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Ealdir Ambusher - Melon Juice');
-- Fallen Crusader (level 21-22, undead)
UPDATE `creature_template` SET `lootid` = 164997 WHERE `entry` = 164997;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164997 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164997, 1, 1000121, 0, 0, 1, 5, 1, 1, 'Fallen Crusader - World Loot Level 21'),
(164997, 2, 1000122, 0, 0, 1, 5, 1, 1, 'Fallen Crusader - World Loot Level 22'),
(164997, 2592, 0, 19.1, 0, 1, 0, 1, 2, 'Fallen Crusader - Wool Cloth'),
(164997, 2589, 0, 18.63, 0, 1, 0, 1, 3, 'Fallen Crusader - Linen Cloth'),
(164997, 1179, 0, 2.67, 0, 1, 0, 1, 1, 'Fallen Crusader - Ice Cold Milk'),
(164997, 4605, 0, 5.07, 0, 1, 0, 1, 1, 'Fallen Crusader - Red-speckled Mushroom'),
(164997, 4606, 0, 4.83, 0, 1, 0, 1, 1, 'Fallen Crusader - Spongy Morel'),
(164997, 1205, 0, 2.39, 0, 1, 0, 1, 1, 'Fallen Crusader - Melon Juice');
-- Possessed Statue of the Cardinal (level 22-22, humanoid)
UPDATE `creature_template` SET `lootid` = 164999 WHERE `entry` = 164999;
DELETE FROM `creature_loot_template` WHERE `Entry` = 164999 AND NOT (`Reference` = 0 AND (`QuestRequired` = 1 OR `Item` >= 500000));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164999, 1, 1000122, 0, 0, 1, 5, 1, 1, 'Possessed Statue of the Cardinal - World Loot Level 22'),
(164999, 2592, 0, 19.59, 0, 1, 0, 1, 2, 'Possessed Statue of the Cardinal - Wool Cloth'),
(164999, 2589, 0, 13.51, 0, 1, 0, 1, 3, 'Possessed Statue of the Cardinal - Linen Cloth'),
(164999, 1205, 0, 2.4, 0, 1, 0, 1, 1, 'Possessed Statue of the Cardinal - Melon Juice'),
(164999, 4306, 0, 5.07, 0, 1, 0, 1, 2, 'Possessed Statue of the Cardinal - Silk Cloth'),
(164999, 1179, 0, 2.4, 0, 1, 0, 1, 1, 'Possessed Statue of the Cardinal - Ice Cold Milk');
