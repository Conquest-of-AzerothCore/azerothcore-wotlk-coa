-- Zul'Gurub, tester feedback round 3 (Hakkar).
-- A Son of Hakkar leaves its Pool of Poisoned Blood only where it dies (boss_hakkar_coa), not during combat.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 11357 AND `source_type` = 0 AND `id` = 3;

-- Standing in several Pools of Corrupted Blood hurts only as much as standing in one.
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 2118606;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(2118606, 536870912);

-- The Heart of Hakkar's display 28887 names a model path the client cannot load; 428001 is the same heart
-- with a valid path. Live shows it at scale 2 inside Hakkar's chest: a combat reach of 13 lets melee at his
-- feet hit it 8 yards up while a hunter's minimum range still ends about 21 yards away.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 92005;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(92005, 0, 428001, 2, 1, 0);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 428001;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(428001, 0.5, 6.5, 2, 0);

-- The Cache of the Blood God holds one of Hakkar's own items for its tier, never the Heart (tester, live, 2026-11-04).
-- None of the four had loot or the loot flag, so they could not be opened.
UPDATE `item_template` SET `Flags` = `Flags` | 4, `ScriptName` = 'item_coa_dungeon_spoils' WHERE `entry` IN (1400023, 1400039, 2400039, 2500039);

DELETE FROM `item_loot_template` WHERE `Entry` IN (1400023, 1400039, 2400039, 2500039);
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(1400023, 19852, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Ancient Hakkari Manslayer'),
(1400023, 19853, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Gurubashi Dwarf Destroyer'),
(1400023, 19854, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Zin\'rokh, Destroyer of Worlds'),
(1400023, 19855, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodsoaked Legplates'),
(1400023, 19856, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - The Eye of Hakkar'),
(1400023, 19857, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Cloak of Consumption'),
(1400023, 19859, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Fang of the Faceless'),
(1400023, 19861, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Touch of Chaos'),
(1400023, 19862, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Aegis of the Blood God'),
(1400023, 19864, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodcaller'),
(1400023, 19865, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Warblade of the Hakkari'),
(1400023, 19876, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Soul Corrupter\'s Necklace'),
(1400023, 20257, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Seafury Gauntlets'),
(1400023, 20264, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Peacekeeper Gauntlets'),
(1400039, 319852, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Ancient Hakkari Manslayer'),
(1400039, 319853, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Gurubashi Dwarf Destroyer'),
(1400039, 319854, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Zin\'rokh, Destroyer of Worlds'),
(1400039, 319855, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodsoaked Legplates'),
(1400039, 319856, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - The Eye of Hakkar'),
(1400039, 319857, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Cloak of Consumption'),
(1400039, 319859, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Fang of the Faceless'),
(1400039, 319861, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Touch of Chaos'),
(1400039, 319862, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Aegis of the Blood God'),
(1400039, 319864, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodcaller'),
(1400039, 319865, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Warblade of the Hakkari'),
(1400039, 319876, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Soul Corrupter\'s Necklace'),
(1400039, 320257, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Seafury Gauntlets'),
(1400039, 320264, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Peacekeeper Gauntlets'),
(2400039, 1319852, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Ancient Hakkari Manslayer'),
(2400039, 1319853, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Gurubashi Dwarf Destroyer'),
(2400039, 1319854, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Zin\'rokh, Destroyer of Worlds'),
(2400039, 1319855, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodsoaked Legplates'),
(2400039, 1319856, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - The Eye of Hakkar'),
(2400039, 1319857, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Cloak of Consumption'),
(2400039, 1319859, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Fang of the Faceless'),
(2400039, 1319861, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Touch of Chaos'),
(2400039, 1319862, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Aegis of the Blood God'),
(2400039, 1319864, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodcaller'),
(2400039, 1319865, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Warblade of the Hakkari'),
(2400039, 1319876, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Soul Corrupter\'s Necklace'),
(2400039, 1320257, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Seafury Gauntlets'),
(2400039, 1320264, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Peacekeeper Gauntlets'),
(2500039, 219852, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Ancient Hakkari Manslayer'),
(2500039, 219853, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Gurubashi Dwarf Destroyer'),
(2500039, 219854, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Zin\'rokh, Destroyer of Worlds'),
(2500039, 219855, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodsoaked Legplates'),
(2500039, 219856, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - The Eye of Hakkar'),
(2500039, 219857, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Cloak of Consumption'),
(2500039, 219859, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Fang of the Faceless'),
(2500039, 219861, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Touch of Chaos'),
(2500039, 219862, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Aegis of the Blood God'),
(2500039, 219864, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Bloodcaller'),
(2500039, 219865, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Warblade of the Hakkari'),
(2500039, 219876, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Soul Corrupter\'s Necklace'),
(2500039, 220257, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Seafury Gauntlets'),
(2500039, 220264, 0, 0, 0, 1, 1, 1, 1, 'Cache of the Blood God - Peacekeeper Gauntlets');
