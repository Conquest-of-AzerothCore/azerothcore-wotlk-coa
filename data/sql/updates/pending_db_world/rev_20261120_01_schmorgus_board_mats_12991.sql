-- Azerothian Schmorgus Board, Spicy Dino Jerky and Chilled Lava Eel materials and recipes (#12991).
-- Devilsaur Meat 100596, Dino Meat 100589, Lava Eel 100578 and Shard of Nevermelting Ice 100586 had no source, and
-- Recipe: Spicy Dino Jerky 100614 and Recipe: Chilled Lava Eel 100621 could not be obtained.
-- Drops and the recipe vendor are the Ascension export (exiles-db-export, 2026-09-13); only creatures present here
-- are listed. The Lava Eel zones come from the Ascension article "Cooking up a Storm!" (Blackrock Depths, Blackrock
-- Mountain, Fire Plume Ridge). The article gives no rate: 30% matches Dino Meat, and a missed roll falls through to
-- the default fishing loot.
DELETE FROM `creature_loot_template` WHERE `Item` = 100596 AND `Entry` IN (6498, 6499, 6500, 6584);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(6498, 100596, 0, 100, 0, 1, 0, 1, 1, 'Devilsaur - Devilsaur Meat'),
(6499, 100596, 0, 100, 0, 1, 0, 1, 1, 'Ironhide Devilsaur - Devilsaur Meat'),
(6500, 100596, 0, 100, 0, 1, 0, 1, 1, 'Tyrant Devilsaur - Devilsaur Meat'),
(6584, 100596, 0, 100, 0, 1, 0, 1, 1, 'King Mosh - Devilsaur Meat');

DELETE FROM `creature_loot_template` WHERE `Item` = 100589 AND `Entry` IN (9162, 9163, 9164, 13323);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(9162, 100589, 0, 30, 0, 1, 0, 1, 1, 'Young Diemetradon - Dino Meat'),
(9163, 100589, 0, 30, 0, 1, 0, 1, 1, 'Diemetradon - Dino Meat'),
(9164, 100589, 0, 30, 0, 1, 0, 1, 1, 'Elder Diemetradon - Dino Meat'),
(13323, 100589, 0, 30, 0, 1, 0, 1, 1, 'Subterranean Diemetradon - Dino Meat');

DELETE FROM `fishing_loot_template` WHERE `Item` = 100578 AND `Entry` IN (25, 537, 1584);
INSERT INTO `fishing_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(25, 100578, 0, 30, 0, 1, 0, 1, 1, 'Blackrock Mountain - Lava Eel'),
(537, 100578, 0, 30, 0, 1, 0, 1, 1, 'Fire Plume Ridge - Lava Eel'),
(1584, 100578, 0, 30, 0, 1, 0, 1, 1, 'Blackrock Depths - Lava Eel');

DELETE FROM `creature_loot_template` WHERE `Item` = 100586 AND `Entry` IN (7428, 7429);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(7428, 100586, 0, 50, 0, 1, 0, 1, 1, 'Frostmaul Giant - Shard of Nevermelting Ice'),
(7429, 100586, 0, 50, 0, 1, 0, 1, 1, 'Frostmaul Preserver - Shard of Nevermelting Ice');

DELETE FROM `creature_loot_template` WHERE `Item` = 100614 AND `Entry` IN (
    6498, 6499, 6500, 6501, 6502, 6503, 6504, 6505, 6506, 6507, 6508, 6581, 6583, 6584, 9162, 9163,
    9164, 9165, 9166, 9167, 13323);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(6498, 100614, 0, 1.25, 0, 1, 0, 1, 1, 'Devilsaur - Recipe: Spicy Dino Jerky'),
(6499, 100614, 0, 1.25, 0, 1, 0, 1, 1, 'Ironhide Devilsaur - Recipe: Spicy Dino Jerky'),
(6500, 100614, 0, 1.25, 0, 1, 0, 1, 1, 'Tyrant Devilsaur - Recipe: Spicy Dino Jerky'),
(6501, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Stegodon - Recipe: Spicy Dino Jerky'),
(6502, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Plated Stegodon - Recipe: Spicy Dino Jerky'),
(6503, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Spiked Stegodon - Recipe: Spicy Dino Jerky'),
(6504, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Thunderstomp Stegodon - Recipe: Spicy Dino Jerky'),
(6505, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Ravasaur - Recipe: Spicy Dino Jerky'),
(6506, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Ravasaur Runner - Recipe: Spicy Dino Jerky'),
(6507, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Ravasaur Hunter - Recipe: Spicy Dino Jerky'),
(6508, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Venomhide Ravasaur - Recipe: Spicy Dino Jerky'),
(6581, 100614, 0, 0.5, 0, 1, 0, 1, 1, 'Ravasaur Matriarch - Recipe: Spicy Dino Jerky'),
(6583, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Gruff - Recipe: Spicy Dino Jerky'),
(6584, 100614, 0, 25, 0, 1, 0, 1, 1, 'King Mosh - Recipe: Spicy Dino Jerky'),
(9162, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Young Diemetradon - Recipe: Spicy Dino Jerky'),
(9163, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Diemetradon - Recipe: Spicy Dino Jerky'),
(9164, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Elder Diemetradon - Recipe: Spicy Dino Jerky'),
(9165, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Fledgling Pterrordax - Recipe: Spicy Dino Jerky'),
(9166, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Pterrordax - Recipe: Spicy Dino Jerky'),
(9167, 100614, 0, 0.25, 0, 1, 0, 1, 1, 'Frenzied Pterrordax - Recipe: Spicy Dino Jerky'),
(13323, 100614, 0, 0.5, 0, 1, 0, 1, 1, 'Subterranean Diemetradon - Recipe: Spicy Dino Jerky');

DELETE FROM `npc_vendor` WHERE `entry` = 9499 AND `item` = 100621;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(9499, 0, 100621, 0, 0, 0, 0);
