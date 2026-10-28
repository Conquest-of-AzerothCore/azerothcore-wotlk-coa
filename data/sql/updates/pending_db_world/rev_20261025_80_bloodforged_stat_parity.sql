-- Bloodforged items: restore the stat lines of the Conquest of Azeroth cache for 72 rows whose stats do not
-- follow Ascension's Bloodforged conversion (a twin keeps about 85% of its source item's stats).
-- Only stat columns are written, plus the equip spell of Orb of the Forgotten Seer; every statement sets fixed
-- values, so a reapply leaves the result unchanged.

-- Bloodforged Rod of the Sleepwalker
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 9, `stat_type2` = 6, `stat_value2` = 9, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6001155;

-- Bloodforged Axe of the Enforcer
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 3, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6001454;

-- Bloodforged Tree Bark Jacket
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 5, `stat_type2` = 5, `stat_value2` = 9, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6001486;

-- Bloodforged Tanglewood Staff
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 15, `stat_type2` = 4, `stat_value2` = 6, `stat_type3` = 45, `stat_value3` = 11, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6001720;

-- Bloodforged Precisely Calibrated Boomstick
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 12, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6002100;

-- Bloodforged Death Speaker Scepter
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 1, `stat_type2` = 45, `stat_value2` = 8, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6002816;

-- Bloodforged Prison Shank
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 4, `stat_type2` = 7, `stat_value2` = 2, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6002941;

-- Bloodforged Naga Heartpiercer
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 4, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6003078;

-- Bloodforged Arced War Axe
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 9, `stat_type2` = 7, `stat_value2` = 8, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6003191;

-- Bloodforged Black Wolf Bracers
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 7, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6003230;

-- Bloodforged Staff of the Friar
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 9, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 5, `stat_value3` = 3, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6003415;

-- Bloodforged Onyx Claymore
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 5, `stat_type2` = 7, `stat_value2` = 4, `stat_type3` = 4, `stat_value3` = 8, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6003417;

-- Bloodforged Feline Mantle
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 8, `stat_type2` = 6, `stat_value2` = 4, `stat_type3` = 45, `stat_value3` = 2, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6003748;

-- Bloodforged Pugilist Bracers
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 7, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6004438;

-- Bloodforged Rhahk'Zor's Hammer
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 9, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6005187;

-- Bloodforged Thief's Blade
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 6, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6005192;

-- Bloodforged Cape of the Brotherhood
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 5, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6005193;

-- Bloodforged Gold-flecked Gloves
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 5, `stat_type2` = 45, `stat_value2` = 6, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6005195;

-- Bloodforged Impaling Harpoon
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 10, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6005200;

-- Bloodforged Rugged Spaulders
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 7, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6005254;

-- Bloodforged Bloody Apron
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 10, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006226;

-- Bloodforged Wolfmaster Cape
UPDATE `item_template` SET `stat_type1` = 13, `stat_value1` = 5, `stat_type2` = 3, `stat_value2` = 4, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006314;

-- Bloodforged Odo's Ley Staff
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 10, `stat_type2` = 7, `stat_value2` = 4, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006318;

-- Bloodforged Girdle of the Blindwatcher
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 6, `stat_type2` = 5, `stat_value2` = 7, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006319;

-- Bloodforged Robes of Arugal
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 3, `stat_type2` = 5, `stat_value2` = 8, `stat_type3` = 7, `stat_value3` = 4, `stat_type4` = 45, `stat_value4` = 10, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006324;

-- Bloodforged Worn Turtle Shell Shield
UPDATE `item_template` SET `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006447;

-- Bloodforged Glowing Lizardscale Cloak
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 5, `stat_type2` = 7, `stat_value2` = 2, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006449;

-- Bloodforged Savage Trodders
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 8, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006459;

-- Bloodforged Cobrahn's Grasp
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 7, `stat_type2` = 3, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006460;

-- Bloodforged Robe of the Moccasin
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 5, `stat_type2` = 7, `stat_value2` = 5, `stat_type3` = 45, `stat_value3` = 6, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006465;

-- Bloodforged Mutant Scale Breastplate
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 11, `stat_type2` = 7, `stat_value2` = 4, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006627;

-- Bloodforged Sporid Cape
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 4, `stat_type2` = 6, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006629;

-- Bloodforged Seedcloud Buckler
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 3, `stat_type2` = 5, `stat_value2` = 5, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006630;

-- Bloodforged Butcher's Slicer
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 3, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006633;

-- Bloodforged Haunting Blade
UPDATE `item_template` SET `stat_type1` = 38, `stat_value1` = 24, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006641;

-- Bloodforged Phantom Armor
UPDATE `item_template` SET `stat_type1` = 32, `stat_value1` = 4, `stat_type2` = 7, `stat_value2` = 9, `stat_type3` = 4, `stat_value3` = 3, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006642;

-- Bloodforged Thornspike
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 7, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006681;

-- Bloodforged Death Speaker Robes
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 3, `stat_type2` = 5, `stat_value2` = 7, `stat_type3` = 6, `stat_value3` = 5, `stat_type4` = 32, `stat_value4` = 10, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006682;

-- Bloodforged Death Speaker Mantle
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 6, `stat_type2` = 6, `stat_value2` = 3, `stat_type3` = 45, `stat_value3` = 8, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006685;

-- Bloodforged Wind Spirit Staff
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 4, `stat_type2` = 6, `stat_value2` = 13, `stat_type3` = 7, `stat_value3` = 3, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006689;

-- Bloodforged Ferine Leggings
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 10, `stat_type2` = 3, `stat_value2` = 11, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006690;

-- Bloodforged Agamaggan's Clutch
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 8, `stat_type2` = 7, `stat_value2` = 4, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006693;

-- Bloodforged Stygian Bone Amulet
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 7, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006695;

-- Bloodforged Glowing Thresher Cape
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 7, `stat_type2` = 5, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006901;

-- Bloodforged Bands of Serra'kis
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 3, `stat_type2` = 7, `stat_value2` = 2, `stat_type3` = 3, `stat_value3` = 5, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006902;

-- Bloodforged Algae Fists
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 9, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6006906;

-- Bloodforged Smite's Mighty Hammer
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 9, `stat_type2` = 3, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007230;

-- Bloodforged Orb of the Forgotten Seer
UPDATE `item_template` SET `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0, `spellid_3` = 460612, `spelltrigger_3` = 1, `spellcharges_3` = 0, `spellcooldown_3` = 0, `spellcategory_3` = 0, `spellcategorycooldown_3` = 0 WHERE `entry` = 6007685;

-- Bloodforged Ironspine's Eye
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 8, `stat_type2` = 4, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007686;

-- Bloodforged Ironspine's Ribcage
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 14, `stat_type2` = 4, `stat_value2` = 5, `stat_type3` = 3, `stat_value3` = 3, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007688;

-- Bloodforged Morbid Dawn
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 13, `stat_type2` = 4, `stat_value2` = 9, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007689;

-- Bloodforged Ebon Vise
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 3, `stat_type2` = 3, `stat_value2` = 5, `stat_type3` = 7, `stat_value3` = 7, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007690;

-- Bloodforged Necrotic Wand
UPDATE `item_template` SET `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007708;

-- Bloodforged Illusionary Rod
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 13, `stat_type2` = 7, `stat_value2` = 6, `stat_type3` = 32, `stat_value3` = 9, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007713;

-- Bloodforged Raging Berserker's Helm
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 7, `stat_type2` = 4, `stat_value2` = 11, `stat_type3` = 32, `stat_value3` = 12, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007719;

-- Bloodforged Ghostshard Talisman
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 8, `stat_type2` = 45, `stat_value2` = 4, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6007731;

-- Bloodforged Revelosh's Armguards
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 7, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009388;

-- Bloodforged Legguards of the Vault
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 4, `stat_type2` = 31, `stat_value2` = 4, `stat_type3` = 7, `stat_value3` = 11, `stat_type4` = 38, `stat_value4` = 22, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009396;

-- Bloodforged Monolithic Bow
UPDATE `item_template` SET `stat_type1` = 3, `stat_value1` = 3, `stat_type2` = 38, `stat_value2` = 10, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009426;

-- Bloodforged Unearthed Bands
UPDATE `item_template` SET `stat_type1` = 38, `stat_value1` = 7, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009428;

-- Bloodforged Forgotten Wraps
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 11, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 45, `stat_value3` = 3, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009433;

-- Bloodforged Electrocutioner Lagnut
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 8, `stat_type2` = 7, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009447;

-- Bloodforged Spidertank Oilrag
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 5, `stat_type2` = 43, `stat_value2` = 3, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009448;

-- Bloodforged Gnomebot Operating Boots
UPDATE `item_template` SET `stat_type1` = 7, `stat_value1` = 7, `stat_type2` = 5, `stat_value2` = 3, `stat_type3` = 43, `stat_value3` = 4, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009450;

-- Bloodforged Big Bad Pauldrons
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 10, `stat_type2` = 7, `stat_value2` = 10, `stat_type3` = 32, `stat_value3` = 7, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009476;

-- Bloodforged Hi-tech Supergun
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 2, `stat_type2` = 45, `stat_value2` = 5, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6009487;

-- Bloodforged Executioner's Cleaver
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 20, `stat_type2` = 31, `stat_value2` = 9, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6013018;

-- Bloodforged Needle Threader
UPDATE `item_template` SET `stat_type1` = 6, `stat_value1` = 3, `stat_type2` = 7, `stat_value2` = 5, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6013021;

-- Bloodforged Skull Splitting Crossbow
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 3, `stat_type2` = 38, `stat_value2` = 12, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6013039;

-- Bloodforged Giantslayer Bracers
UPDATE `item_template` SET `stat_type1` = 4, `stat_value1` = 9, `stat_type2` = 3, `stat_value2` = 4, `stat_type3` = 7, `stat_value3` = 5, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6013076;

-- Bloodforged Brusslehide Leggings
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 18, `stat_type2` = 7, `stat_value2` = 12, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6017751;

-- Bloodforged Inquisitor's Shawl
UPDATE `item_template` SET `stat_type1` = 5, `stat_value1` = 10, `stat_type2` = 45, `stat_value2` = 11, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0 WHERE `entry` = 6019507;
