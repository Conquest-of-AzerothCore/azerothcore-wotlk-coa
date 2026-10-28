-- Dun Kazad's crafters, fishers and inn: each its own dwarf with a dwarvish name, keeping its trade (trainer, vendor
-- list, weapons) but none of the quests of the NPC it was copied from. Yrsa and Brokk Embervial were human and are
-- now dwarves wearing the same clothes. The innkeeper is now Ulfgar Kazadbrew, Brewmaster, selling ales and mead,
-- among them Dun Kazad Dark Ale; he is a shopkeeper, not an innkeeper. Props placed around the shops can no longer be clicked or looted.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(165623, 0, 0, 0, 0, 0, 'Brenna Deeprock', 'Leatherworking Trainer', NULL, 4172, 22, 22, 0, 12, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.02, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165624, 0, 0, 0, 0, 0, 'Tormund Deeprock', 'Leatherworking Supplies', NULL, 0, 31, 31, 0, 12, 128, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 4608, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.12, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165625, 0, 0, 0, 0, 0, 'Sigra Kazadmere', 'Fishing Supplies', NULL, 0, 15, 15, 0, 55, 640, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165626, 0, 0, 0, 0, 0, 'Haldor Kazadmere', 'Fishing Trainer', NULL, 5665, 15, 15, 0, 55, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165627, 0, 0, 0, 0, 0, 'Yrsa Embervial', 'Alchemy Trainer', NULL, 4110, 26, 26, 0, 12, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.064, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165628, 0, 0, 0, 0, 0, 'Brokk Embervial', 'Alchemy Supplies & Reagents', NULL, 685, 30, 30, 0, 12, 2177, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.072, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165629, 0, 0, 0, 0, 0, 'Hagren Forgeheart', 'Blacksmithing Trainer', NULL, 593, 45, 45, 0, 55, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.264, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165630, 0, 0, 0, 0, 0, 'Bodvar Forgeheart', 'Blacksmithing Supplies', NULL, 0, 29, 29, 0, 55, 4224, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.072, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165631, 0, 0, 0, 0, 0, 'Gimrik Stonedelve', 'Mining Trainer', NULL, 7690, 10, 10, 0, 55, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340),
(165632, 0, 0, 0, 0, 0, 'Ulfgar Kazadbrew', 'Brewmaster', NULL, 345, 30, 30, 0, 55, 66177, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 2147483648, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.072, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (165623, 165624, 165625, 165626, 165627, 165628, 165629, 165630, 165631, 165632);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(165623, 0, 54, 1, 1, 0),
(165624, 0, 53, 1, 1, 0),
(165625, 0, 1843, 1, 1, 51831),
(165626, 0, 1848, 1, 1, 51831),
(165627, 0, 54, 1, 1, 51831),
(165628, 0, 53, 1, 1, 51831),
(165629, 0, 3097, 1, 1, 12340),
(165630, 0, 3427, 1, 1, 51831),
(165631, 0, 3424, 1, 1, 51831),
(165632, 0, 3047, 1, 1, 51831);
DELETE FROM `creature_display_preset` WHERE `entry` IN (165623, 165624, 165625, 165626, 165627, 165628, 165629, 165630, 165631, 165632);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(165623, 54, 3, 1, 1, 0, 0, 0, 0, 0, 0, 10212, 206, 0, 25037, 0, 34157, 36709, 4156, 0, 0, 0),
(165624, 53, 3, 0, 1, 0, 0, 0, 0, 0, 0, 16628, 5424, 0, 45011, 0, 34157, 36709, 4156, 0, 0, 0),
(165627, 54, 3, 1, 1, 3, 2, 2, 3, 0, 0, 12504, 6808, 0, 9954, 7020, 8398, 3921, 0, 0, 0, 0),
(165628, 53, 3, 0, 1, 0, 0, 0, 0, 0, 0, 252, 0, 6873, 0, 3384, 3385, 3386, 0, 0, 0, 0);
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (165623, 165624, 165625, 165626, 165627, 165628, 165629, 165630, 165631, 165632);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(165627, 1, 2198, 3694, 0, 18019),
(165628, 1, 3699, 0, 0, 18019),
(165629, 1, 1903, 0, 0, 18019),
(165630, 1, 1903, 0, 0, 18019),
(165631, 1, 1910, 2714, 0, 18019),
(165632, 1, 2705, 0, 0, 18019);
DELETE FROM `creature_template_addon` WHERE `entry` IN (165623, 165624, 165625, 165626, 165627, 165628, 165629, 165630, 165631, 165632);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(165623, 0, 0, 0, 1, 0, 0, NULL),
(165628, 0, 0, 0, 1, 0, 0, NULL),
(165629, 0, 0, 0, 1, 233, 0, NULL),
(165630, 0, 0, 0, 1, 0, 0, NULL),
(165631, 0, 0, 0, 1, 0, 0, NULL),
(165632, 0, 0, 0, 1, 0, 0, NULL);
DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (165623, 165624, 165625, 165626, 165627, 165628, 165629, 165630, 165631, 165632);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(165623, 61),
(165626, 98),
(165627, 67),
(165629, 60),
(165631, 80);
DELETE FROM `npc_vendor` WHERE `entry` IN (165623, 165624, 165625, 165626, 165627, 165628, 165629, 165630, 165631, 165632);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(165624, 0, 2320, 0, 0, 0, 0),
(165624, 0, 2321, 0, 0, 0, 0),
(165624, 0, 2325, 0, 0, 0, 0),
(165624, 0, 2604, 0, 0, 0, 0),
(165624, 0, 2605, 0, 0, 0, 0),
(165624, 0, 4289, 0, 0, 0, 0),
(165624, 0, 4291, 0, 0, 0, 0),
(165624, 0, 4340, 0, 0, 0, 0),
(165624, 0, 4341, 0, 0, 0, 0),
(165624, 0, 4342, 0, 0, 0, 0),
(165624, 0, 6260, 0, 0, 0, 0),
(165624, 0, 6261, 0, 0, 0, 0),
(165624, 0, 7005, 0, 0, 0, 0),
(165624, 0, 7289, 1, 9000, 0, 0),
(165624, 0, 8343, 0, 0, 0, 0),
(165624, 0, 10290, 0, 0, 0, 0),
(165624, 0, 14341, 0, 0, 0, 0),
(165624, 0, 38426, 0, 0, 0, 0),
(165625, 0, 787, 0, 0, 0, 0),
(165625, 0, 4592, 0, 0, 0, 0),
(165625, 0, 4593, 0, 0, 0, 0),
(165625, 0, 4594, 0, 0, 0, 0),
(165625, 0, 6256, 0, 0, 0, 0),
(165625, 0, 6325, 0, 0, 0, 0),
(165625, 0, 6328, 0, 0, 0, 0),
(165625, 0, 6329, 0, 0, 0, 0),
(165625, 0, 6365, 1, 9000, 0, 0),
(165625, 0, 6529, 0, 0, 0, 0),
(165625, 0, 6530, 0, 0, 0, 0),
(165625, 0, 6532, 0, 0, 0, 0),
(165625, 0, 6533, 2, 43200, 0, 0),
(165625, 0, 8957, 0, 0, 0, 0),
(165625, 0, 21552, 0, 0, 0, 0),
(165628, 0, 858, 3, 9000, 0, 0),
(165628, 0, 3371, 0, 0, 0, 0),
(165628, 0, 3372, 0, 0, 0, 0),
(165628, 0, 5565, 0, 0, 0, 0),
(165628, 0, 8925, 0, 0, 0, 0),
(165628, 0, 16583, 0, 0, 0, 0),
(165628, 0, 17020, 0, 0, 0, 0),
(165628, 0, 17021, 0, 0, 0, 0),
(165628, 0, 17026, 0, 0, 0, 0),
(165628, 0, 17028, 0, 0, 0, 0),
(165628, 0, 17029, 0, 0, 0, 0),
(165628, 0, 17030, 0, 0, 0, 0),
(165628, 0, 17031, 0, 0, 0, 0),
(165628, 0, 17032, 0, 0, 0, 0),
(165628, 0, 17033, 0, 0, 0, 0),
(165628, 0, 17034, 0, 0, 0, 0),
(165628, 0, 17035, 0, 0, 0, 0),
(165628, 0, 17036, 0, 0, 0, 0),
(165628, 0, 17037, 0, 0, 0, 0),
(165628, 0, 17038, 0, 0, 0, 0),
(165628, 0, 18256, 0, 0, 0, 0),
(165628, 0, 21177, 0, 0, 0, 0),
(165628, 0, 22147, 0, 0, 0, 0),
(165628, 0, 22148, 0, 0, 0, 0),
(165628, 0, 37201, 0, 0, 0, 0),
(165628, 0, 40411, 0, 0, 0, 0),
(165628, 0, 44605, 0, 0, 0, 0),
(165628, 0, 44614, 0, 0, 0, 0),
(165628, 0, 44615, 0, 0, 0, 0),
(165630, 0, 2880, 0, 0, 0, 0),
(165630, 0, 2901, 0, 0, 0, 0),
(165630, 0, 3466, 0, 0, 0, 0),
(165630, 0, 3857, 0, 0, 0, 0),
(165630, 0, 5956, 0, 0, 0, 0),
(165630, 0, 18567, 0, 0, 0, 0),
(165632, 0, 772723, 0, 0, 0, 0),
(165632, 1, 2686, 0, 0, 0, 0),
(165632, 2, 2894, 0, 0, 0, 0),
(165632, 3, 2596, 0, 0, 0, 0),
(165632, 4, 3703, 0, 0, 0, 0),
(165632, 5, 3087, 0, 0, 0, 0),
(165632, 6, 2594, 0, 0, 0, 0),
(165632, 7, 4600, 0, 0, 0, 0),
(165632, 8, 2593, 0, 0, 0, 0),
(165632, 9, 2595, 0, 0, 0, 0),
(165632, 10, 2723, 0, 0, 0, 0),
(165632, 11, 1179, 0, 0, 0, 0),
(165632, 12, 159, 0, 0, 0, 0),
(165632, 13, 422, 0, 0, 0, 0),
(165632, 14, 117, 0, 0, 0, 0),
(165632, 15, 2287, 0, 0, 0, 0);
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) VALUES
(772723, 0, 5, -1, 'Dun Kazad Dark Ale', 14185, 1, 0, 0, 1, 60, 15, 0, -1, -1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11007, 0, -1, -1, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 'Brewed in the deep halls of Dun Kazad. Thick enough to stand a spoon in.', 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340) ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `SoundOverrideSubclass` = VALUES(`SoundOverrideSubclass`), `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `FlagsExtra` = VALUES(`FlagsExtra`), `BuyCount` = VALUES(`BuyCount`), `BuyPrice` = VALUES(`BuyPrice`), `SellPrice` = VALUES(`SellPrice`), `InventoryType` = VALUES(`InventoryType`), `AllowableClass` = VALUES(`AllowableClass`), `AllowableRace` = VALUES(`AllowableRace`), `ItemLevel` = VALUES(`ItemLevel`), `RequiredLevel` = VALUES(`RequiredLevel`), `RequiredSkill` = VALUES(`RequiredSkill`), `RequiredSkillRank` = VALUES(`RequiredSkillRank`), `requiredspell` = VALUES(`requiredspell`), `requiredhonorrank` = VALUES(`requiredhonorrank`), `RequiredCityRank` = VALUES(`RequiredCityRank`), `RequiredReputationFaction` = VALUES(`RequiredReputationFaction`), `RequiredReputationRank` = VALUES(`RequiredReputationRank`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`), `ContainerSlots` = VALUES(`ContainerSlots`), `stat_type1` = VALUES(`stat_type1`), `stat_value1` = VALUES(`stat_value1`), `stat_type2` = VALUES(`stat_type2`), `stat_value2` = VALUES(`stat_value2`), `stat_type3` = VALUES(`stat_type3`), `stat_value3` = VALUES(`stat_value3`), `stat_type4` = VALUES(`stat_type4`), `stat_value4` = VALUES(`stat_value4`), `stat_type5` = VALUES(`stat_type5`), `stat_value5` = VALUES(`stat_value5`), `stat_type6` = VALUES(`stat_type6`), `stat_value6` = VALUES(`stat_value6`), `stat_type7` = VALUES(`stat_type7`), `stat_value7` = VALUES(`stat_value7`), `stat_type8` = VALUES(`stat_type8`), `stat_value8` = VALUES(`stat_value8`), `stat_type9` = VALUES(`stat_type9`), `stat_value9` = VALUES(`stat_value9`), `stat_type10` = VALUES(`stat_type10`), `stat_value10` = VALUES(`stat_value10`), `ScalingStatDistribution` = VALUES(`ScalingStatDistribution`), `ScalingStatValue` = VALUES(`ScalingStatValue`), `dmg_min1` = VALUES(`dmg_min1`), `dmg_max1` = VALUES(`dmg_max1`), `dmg_type1` = VALUES(`dmg_type1`), `dmg_min2` = VALUES(`dmg_min2`), `dmg_max2` = VALUES(`dmg_max2`), `dmg_type2` = VALUES(`dmg_type2`), `armor` = VALUES(`armor`), `holy_res` = VALUES(`holy_res`), `fire_res` = VALUES(`fire_res`), `nature_res` = VALUES(`nature_res`), `frost_res` = VALUES(`frost_res`), `shadow_res` = VALUES(`shadow_res`), `arcane_res` = VALUES(`arcane_res`), `delay` = VALUES(`delay`), `ammo_type` = VALUES(`ammo_type`), `RangedModRange` = VALUES(`RangedModRange`), `spellid_1` = VALUES(`spellid_1`), `spelltrigger_1` = VALUES(`spelltrigger_1`), `spellcharges_1` = VALUES(`spellcharges_1`), `spellppmRate_1` = VALUES(`spellppmRate_1`), `spellcooldown_1` = VALUES(`spellcooldown_1`), `spellcategory_1` = VALUES(`spellcategory_1`), `spellcategorycooldown_1` = VALUES(`spellcategorycooldown_1`), `spellid_2` = VALUES(`spellid_2`), `spelltrigger_2` = VALUES(`spelltrigger_2`), `spellcharges_2` = VALUES(`spellcharges_2`), `spellppmRate_2` = VALUES(`spellppmRate_2`), `spellcooldown_2` = VALUES(`spellcooldown_2`), `spellcategory_2` = VALUES(`spellcategory_2`), `spellcategorycooldown_2` = VALUES(`spellcategorycooldown_2`), `spellid_3` = VALUES(`spellid_3`), `spelltrigger_3` = VALUES(`spelltrigger_3`), `spellcharges_3` = VALUES(`spellcharges_3`), `spellppmRate_3` = VALUES(`spellppmRate_3`), `spellcooldown_3` = VALUES(`spellcooldown_3`), `spellcategory_3` = VALUES(`spellcategory_3`), `spellcategorycooldown_3` = VALUES(`spellcategorycooldown_3`), `spellid_4` = VALUES(`spellid_4`), `spelltrigger_4` = VALUES(`spelltrigger_4`), `spellcharges_4` = VALUES(`spellcharges_4`), `spellppmRate_4` = VALUES(`spellppmRate_4`), `spellcooldown_4` = VALUES(`spellcooldown_4`), `spellcategory_4` = VALUES(`spellcategory_4`), `spellcategorycooldown_4` = VALUES(`spellcategorycooldown_4`), `spellid_5` = VALUES(`spellid_5`), `spelltrigger_5` = VALUES(`spelltrigger_5`), `spellcharges_5` = VALUES(`spellcharges_5`), `spellppmRate_5` = VALUES(`spellppmRate_5`), `spellcooldown_5` = VALUES(`spellcooldown_5`), `spellcategory_5` = VALUES(`spellcategory_5`), `spellcategorycooldown_5` = VALUES(`spellcategorycooldown_5`), `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `PageText` = VALUES(`PageText`), `LanguageID` = VALUES(`LanguageID`), `PageMaterial` = VALUES(`PageMaterial`), `startquest` = VALUES(`startquest`), `lockid` = VALUES(`lockid`), `Material` = VALUES(`Material`), `sheath` = VALUES(`sheath`), `RandomProperty` = VALUES(`RandomProperty`), `RandomSuffix` = VALUES(`RandomSuffix`), `block` = VALUES(`block`), `itemset` = VALUES(`itemset`), `MaxDurability` = VALUES(`MaxDurability`), `area` = VALUES(`area`), `Map` = VALUES(`Map`), `BagFamily` = VALUES(`BagFamily`), `TotemCategory` = VALUES(`TotemCategory`), `socketColor_1` = VALUES(`socketColor_1`), `socketContent_1` = VALUES(`socketContent_1`), `socketColor_2` = VALUES(`socketColor_2`), `socketContent_2` = VALUES(`socketContent_2`), `socketColor_3` = VALUES(`socketColor_3`), `socketContent_3` = VALUES(`socketContent_3`), `socketBonus` = VALUES(`socketBonus`), `GemProperties` = VALUES(`GemProperties`), `RequiredDisenchantSkill` = VALUES(`RequiredDisenchantSkill`), `ArmorDamageModifier` = VALUES(`ArmorDamageModifier`), `duration` = VALUES(`duration`), `ItemLimitCategory` = VALUES(`ItemLimitCategory`), `HolidayId` = VALUES(`HolidayId`), `ScriptName` = VALUES(`ScriptName`), `DisenchantID` = VALUES(`DisenchantID`), `FoodType` = VALUES(`FoodType`), `minMoneyLoot` = VALUES(`minMoneyLoot`), `maxMoneyLoot` = VALUES(`maxMoneyLoot`), `flagsCustom` = VALUES(`flagsCustom`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature` WHERE `guid` IN (9999225, 9999226, 9999234, 9999235, 9999240, 9999241, 9999246, 9999252, 9999251, 9999257);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9999225, 165623, 0, 0, 0, 1, 1, 0, -6627.89, -191.825, 570.542, 2.55878, 300, 0, 0, 574, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999226, 165624, 0, 0, 0, 1, 1, 0, -6629.08, -193.382, 570.543, 2.43704, 300, 0, 0, 1127, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999234, 165625, 0, 0, 0, 1, 1, 0, -6513.31, -363.474, 565.702, 2.73265, 300, 0, 0, 328, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999235, 165626, 0, 0, 0, 1, 1, 0, -6513.09, -370.006, 565.096, 4.20685, 300, 0, 0, 328, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999240, 165627, 0, 0, 0, 1, 1, 1, -6617.23, -104.42, 572.133, 2.03128, 300, 0, 0, 798, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999241, 165628, 0, 0, 0, 1, 1, 1, -6620.85, -106.412, 572.047, 1.21211, 300, 0, 0, 1024, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999246, 165629, 0, 0, 0, 1, 1, 1, -6647.38, -180.864, 570.549, 4.8076, 300, 0, 0, 2336, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999252, 165630, 0, 0, 0, 1, 1, 1, -6641.02, -188.462, 570.448, 4.7628, 300, 0, 0, 971, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999251, 165631, 0, 0, 0, 1, 1, 1, -6645.42, -185.589, 570.548, 3.35303, 300, 0, 0, 195, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999257, 165632, 0, 0, 0, 1, 1, 1, -6474.75, -234.713, 568.448, 3.04123, 300, 0, 0, 1024, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
DELETE FROM `creature_addon` WHERE `guid` IN (9999251);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9999251, 0, 0, 0, 1, 69, 0, NULL);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300814, 5, 1014316, 'Travel Sack', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300815, 5, 1026950, 'Alchemy Visceral Juice', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300816, 5, 7142, 'Daggerfen Poison Vial', '', '', '', 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300817, 5, 345, 'Alchemical Implements', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300818, 5, 130, 'Agamand Weapon Rack', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300820, 5, 1014746, 'Miner''s Pickaxe', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300821, 5, 36, 'Irondeep Supplies', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300822, 5, 1, 'Storage Chest', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300823, 5, 181, 'Locked ball and chain', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `gameobject` WHERE `guid` IN (9999431, 9999436, 9999437, 9999438, 9999435, 9999454, 9999465, 9999466, 9999468, 9999469, 9999393);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9999431, 2300814, 0, 0, 0, 1, 1, -6628.99, -191.207, 571.396, 0.0402814, 0, 0, 0.0201394, 0.999797, 300, 0, 1, '', NULL, NULL),
(9999436, 2300815, 0, 0, 0, 1, 1, -6618.85, -103.316, 573.02, 0.172247, 0, 0, 0.0860169, 0.996294, 300, 0, 1, '', NULL, NULL),
(9999437, 2300815, 0, 0, 0, 1, 1, -6619.65, -103.454, 573.02, 0.172247, 0, 0, 0.0860169, 0.996294, 300, 0, 1, '', NULL, NULL),
(9999438, 2300816, 0, 0, 0, 1, 1, -6619.65, -103.454, 573.02, 0.172247, 0, 0, 0.0860169, 0.996294, 300, 0, 1, '', NULL, NULL),
(9999435, 2300817, 0, 0, 0, 1, 1, -6616.98, -102.457, 573.021, 1.90248, 0, 0, 0.814135, 0.580676, 0, 0, 1, '', NULL, NULL),
(9999454, 2300818, 0, 0, 0, 1, 1, -6644.64, -188.787, 570.548, 5.6103, -0, -0, -0.330131, 0.943935, 300, 0, 1, '', NULL, NULL),
(9999466, 2300820, 0, 0, 0, 1, 1, -6646.51, -176.535, 571.148, 0.3552, 0.305943, -0.435768, -0.27516, -0.800495, 300, 0, 1, '', NULL, NULL),
(9999468, 2300821, 0, 0, 0, 1, 1, -6641.59, -189.6, 570.548, 0.3154, -0, -0, -0.157047, -0.987591, 300, 0, 1, '', NULL, NULL),
(9999469, 2300822, 0, 0, 0, 1, 1, -6639.51, -189.072, 570.348, 2.1736, -0, -0, -0.885143, -0.46532, 300, 0, 1, '', NULL, NULL),
(9999393, 2300823, 0, 0, 0, 1, 1, -6711.26, -17.7813, 581.31, 1.28174, 0, 0, 0.597893, 0.801576, 300, 0, 1, '', NULL, NULL);
-- A GM-only waypoint marker left behind by recording the flight route.
DELETE FROM `creature` WHERE `guid` = 9999229 AND `id` = 1;
-- Ulfgar Kazadbrew only sells (no inn, no innkeeper chat).
UPDATE `creature_template` SET `npcflag` = 128, `gossip_menu_id` = 0 WHERE `entry` = 165632;
