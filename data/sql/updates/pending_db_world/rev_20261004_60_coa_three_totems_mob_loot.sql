-- Three Totems mobs dropped nothing beyond their quest items (playtest). No source records CoA's drops (the Exiles
-- rows are empty placeholders), so as in Deathknell each takes a stock Mulgore analogue of its kind and level without
-- that table's quest items, and its CoA world loot at its own level where one exists (5 and up): Marauders and
-- Patrols the Bristleback Quilboar 2952; Villagers, Funeral Guards and Belduna the Palemane Tanner 2949; Warriors
-- and Guards the Palemane Skinner 2950; Malgorm the Palemane Poacher 2951 with his own Bracers 626264, and the
-- 15 yd aggro of Deathknell's Aberrant Progeny; Tallstriders the Plainstrider 2955 and its skinning; the
-- Scavengers and the Cruel Carrion Spirit the Wiry Swoop 2969. Coin follows the analogue, Malgorm's the Progeny's.
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 1, `maxgold` = 5 WHERE `entry` IN (161809, 161810);
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 1, `maxgold` = 10
    WHERE `entry` IN (161813, 161815, 161838);
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 2, `maxgold` = 11 WHERE `entry` IN (161814, 161837);
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 10, `maxgold` = 25, `detection_range` = 15
    WHERE `entry` = 161816;
UPDATE `creature_template` SET `lootid` = `entry`, `skinloot` = 100001 WHERE `entry` = 161811;
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (161812, 161834);

DELETE FROM `creature_loot_template` WHERE `Entry` IN (161813, 161815, 161838, 161814, 161837, 161816, 161812, 161834)
    OR (`Entry` IN (161809, 161810, 161811) AND `QuestRequired` = 0);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(161809, 1384, 0, 1.25, 0, 1, 0, 1, 1, 'Grimtotem Marauder - Dull Blade, as Bristleback Quilboar 2952'),
(161809, 0, 20000, 30, 0, 1, 0, 1, 1, 'Grimtotem Marauder - as Bristleback Quilboar 2952'),
(161809, 0, 20014, 30, 0, 1, 0, 1, 1, 'Grimtotem Marauder - as Bristleback Quilboar 2952'),
(161809, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Grimtotem Marauder - as Bristleback Quilboar 2952'),
(161810, 1384, 0, 1.25, 0, 1, 0, 1, 1, 'Grimtotem Patrol - Dull Blade, as Bristleback Quilboar 2952'),
(161810, 0, 20000, 30, 0, 1, 0, 1, 1, 'Grimtotem Patrol - as Bristleback Quilboar 2952'),
(161810, 0, 20014, 30, 0, 1, 0, 1, 1, 'Grimtotem Patrol - as Bristleback Quilboar 2952'),
(161810, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Grimtotem Patrol - as Bristleback Quilboar 2952'),
(161813, 2589, 0, 29.1265, 0, 1, 0, 1, 2, 'Funeral Guard - Linen Cloth, as Palemane Tanner 2949'),
(161813, 117, 0, 7.6649, 0, 1, 0, 1, 1, 'Funeral Guard - Tough Jerky, as Palemane Tanner 2949'),
(161813, 159, 0, 3.8565, 0, 1, 0, 1, 1, 'Funeral Guard - Refreshing Spring Water, as Palemane Tanner 2949'),
(161813, 2070, 0, 0.04, 0, 1, 0, 1, 1, 'Funeral Guard - Darnassian Bleu, as Palemane Tanner 2949'),
(161813, 4604, 0, 0.04, 0, 1, 0, 1, 1, 'Funeral Guard - Forest Mushroom Cap, as Palemane Tanner 2949'),
(161813, 787, 0, 0.02, 0, 1, 0, 1, 1, 'Funeral Guard - Slitherskin Mackerel, as Palemane Tanner 2949'),
(161813, 4536, 0, 0.0096, 0, 1, 0, 2, 2, 'Funeral Guard - Shiny Red Apple, as Palemane Tanner 2949'),
(161813, 4540, 0, 0.0096, 0, 1, 0, 2, 2, 'Funeral Guard - Tough Hunk of Bread, as Palemane Tanner 2949'),
(161813, 1, 1000105, 0, 0, 1, 5, 1, 1, 'Funeral Guard - World Loot Level 5'),
(161815, 2589, 0, 29.1265, 0, 1, 0, 1, 2, 'Grimtotem Villager - Linen Cloth, as Palemane Tanner 2949'),
(161815, 117, 0, 7.6649, 0, 1, 0, 1, 1, 'Grimtotem Villager - Tough Jerky, as Palemane Tanner 2949'),
(161815, 159, 0, 3.8565, 0, 1, 0, 1, 1, 'Grimtotem Villager - Refreshing Spring Water, as Palemane Tanner 2949'),
(161815, 2070, 0, 0.04, 0, 1, 0, 1, 1, 'Grimtotem Villager - Darnassian Bleu, as Palemane Tanner 2949'),
(161815, 4604, 0, 0.04, 0, 1, 0, 1, 1, 'Grimtotem Villager - Forest Mushroom Cap, as Palemane Tanner 2949'),
(161815, 787, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Villager - Slitherskin Mackerel, as Palemane Tanner 2949'),
(161815, 4536, 0, 0.0096, 0, 1, 0, 2, 2, 'Grimtotem Villager - Shiny Red Apple, as Palemane Tanner 2949'),
(161815, 4540, 0, 0.0096, 0, 1, 0, 2, 2, 'Grimtotem Villager - Tough Hunk of Bread, as Palemane Tanner 2949'),
(161815, 1, 1000105, 0, 0, 1, 5, 1, 1, 'Grimtotem Villager - World Loot Level 5'),
(161838, 2589, 0, 29.1265, 0, 1, 0, 1, 2, 'Belduna - Linen Cloth, as Palemane Tanner 2949'),
(161838, 117, 0, 7.6649, 0, 1, 0, 1, 1, 'Belduna - Tough Jerky, as Palemane Tanner 2949'),
(161838, 159, 0, 3.8565, 0, 1, 0, 1, 1, 'Belduna - Refreshing Spring Water, as Palemane Tanner 2949'),
(161838, 2070, 0, 0.04, 0, 1, 0, 1, 1, 'Belduna - Darnassian Bleu, as Palemane Tanner 2949'),
(161838, 4604, 0, 0.04, 0, 1, 0, 1, 1, 'Belduna - Forest Mushroom Cap, as Palemane Tanner 2949'),
(161838, 787, 0, 0.02, 0, 1, 0, 1, 1, 'Belduna - Slitherskin Mackerel, as Palemane Tanner 2949'),
(161838, 4536, 0, 0.0096, 0, 1, 0, 2, 2, 'Belduna - Shiny Red Apple, as Palemane Tanner 2949'),
(161838, 4540, 0, 0.0096, 0, 1, 0, 2, 2, 'Belduna - Tough Hunk of Bread, as Palemane Tanner 2949'),
(161838, 1, 1000105, 0, 0, 1, 5, 1, 1, 'Belduna - World Loot Level 5'),
(161814, 2589, 0, 29.2321, 0, 1, 0, 1, 2, 'Grimtotem Warrior - Linen Cloth, as Palemane Skinner 2950'),
(161814, 117, 0, 7.3672, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Tough Jerky, as Palemane Skinner 2950'),
(161814, 159, 0, 3.5169, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Refreshing Spring Water, as Palemane Skinner 2950'),
(161814, 787, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Slitherskin Mackerel, as Palemane Skinner 2950'),
(161814, 2070, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Darnassian Bleu, as Palemane Skinner 2950'),
(161814, 4536, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Shiny Red Apple, as Palemane Skinner 2950'),
(161814, 4540, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Tough Hunk of Bread, as Palemane Skinner 2950'),
(161814, 4604, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Warrior - Forest Mushroom Cap, as Palemane Skinner 2950'),
(161814, 1, 1000106, 0, 0, 1, 5, 1, 1, 'Grimtotem Warrior - World Loot Level 6'),
(161837, 2589, 0, 29.2321, 0, 1, 0, 1, 2, 'Grimtotem Guard - Linen Cloth, as Palemane Skinner 2950'),
(161837, 117, 0, 7.3672, 0, 1, 0, 1, 1, 'Grimtotem Guard - Tough Jerky, as Palemane Skinner 2950'),
(161837, 159, 0, 3.5169, 0, 1, 0, 1, 1, 'Grimtotem Guard - Refreshing Spring Water, as Palemane Skinner 2950'),
(161837, 787, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Guard - Slitherskin Mackerel, as Palemane Skinner 2950'),
(161837, 2070, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Guard - Darnassian Bleu, as Palemane Skinner 2950'),
(161837, 4536, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Guard - Shiny Red Apple, as Palemane Skinner 2950'),
(161837, 4540, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Guard - Tough Hunk of Bread, as Palemane Skinner 2950'),
(161837, 4604, 0, 0.02, 0, 1, 0, 1, 1, 'Grimtotem Guard - Forest Mushroom Cap, as Palemane Skinner 2950'),
(161837, 1, 1000106, 0, 0, 1, 5, 1, 1, 'Grimtotem Guard - World Loot Level 6'),
(161816, 2589, 0, 30.0378, 0, 1, 0, 1, 2, 'Malgorm Hollowhoof - Linen Cloth, as Palemane Poacher 2951'),
(161816, 117, 0, 8.3762, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Tough Jerky, as Palemane Poacher 2951'),
(161816, 159, 0, 4.4113, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Refreshing Spring Water, as Palemane Poacher 2951'),
(161816, 2070, 0, 0.02, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Darnassian Bleu, as Palemane Poacher 2951'),
(161816, 4536, 0, 0.02, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Shiny Red Apple, as Palemane Poacher 2951'),
(161816, 4604, 0, 0.02, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Forest Mushroom Cap, as Palemane Poacher 2951'),
(161816, 5498, 0, 0.02, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Small Lustrous Pearl, as Palemane Poacher 2951'),
(161816, 1, 1000107, 0, 0, 1, 5, 1, 1, 'Malgorm Hollowhoof - World Loot Level 7'),
(161811, 0, 20005, 100, 0, 1, 0, 1, 1, 'Tallstrider - as Plainstrider 2955'),
(161811, 0, 20005, 30, 0, 1, 1, 1, 1, 'Tallstrider - as Plainstrider 2955'),
(161811, 0, 20000, 20, 0, 1, 0, 1, 1, 'Tallstrider - as Plainstrider 2955'),
(161811, 0, 11111, 0.2, 0, 1, 0, 1, 1, 'Tallstrider - as Plainstrider 2955'),
(161812, 6889, 0, 51.896, 0, 1, 0, 1, 1, 'Battlefield Scavenger - Small Egg, as Wiry Swoop 2969'),
(161812, 4757, 0, 22.1759, 0, 1, 0, 1, 1, 'Battlefield Scavenger - Cracked Egg Shells, as Wiry Swoop 2969'),
(161812, 7096, 0, 21.8384, 0, 1, 0, 1, 1, 'Battlefield Scavenger - Plucked Feather, as Wiry Swoop 2969'),
(161812, 4775, 0, 10.7008, 0, 1, 0, 1, 1, 'Battlefield Scavenger - Cracked Bill, as Wiry Swoop 2969'),
(161812, 7097, 0, 7.3456, 0, 1, 0, 1, 1, 'Battlefield Scavenger - Leg Meat, as Wiry Swoop 2969'),
(161812, 4776, 0, 3.653, 0, 1, 0, 1, 1, 'Battlefield Scavenger - Ruffled Feather, as Wiry Swoop 2969'),
(161834, 6889, 0, 51.896, 0, 1, 0, 1, 1, 'Cruel Carrion Spirit - Small Egg, as Wiry Swoop 2969'),
(161834, 4757, 0, 22.1759, 0, 1, 0, 1, 1, 'Cruel Carrion Spirit - Cracked Egg Shells, as Wiry Swoop 2969'),
(161834, 7096, 0, 21.8384, 0, 1, 0, 1, 1, 'Cruel Carrion Spirit - Plucked Feather, as Wiry Swoop 2969'),
(161834, 4775, 0, 10.7008, 0, 1, 0, 1, 1, 'Cruel Carrion Spirit - Cracked Bill, as Wiry Swoop 2969'),
(161834, 7097, 0, 7.3456, 0, 1, 0, 1, 1, 'Cruel Carrion Spirit - Leg Meat, as Wiry Swoop 2969'),
(161834, 4776, 0, 3.653, 0, 1, 0, 1, 1, 'Cruel Carrion Spirit - Ruffled Feather, as Wiry Swoop 2969'),
(161816, 626264, 0, 100, 0, 1, 0, 1, 1, 'Malgorm Hollowhoof - Malgorm Hollowhoof''s Bracers');

-- Every Grimtotem Marauder drops its Mane while Death and Tribute 1660030 still needs one.
UPDATE `creature_loot_template` SET `Chance` = 100 WHERE `Entry` = 161809 AND `Item` = 559156;
