-- Scrolls of Retreat and of Defense: the two missing items, the teleport
-- destinations all four scrolls cast into, and Tiraxis's two rotation rows.
--
-- The live realm sells the two Scrolls of Defense from Tiraxis beside the Battle
-- Horn, and the two Scrolls of Retreat arrive with the welcome warchest (their item
-- rows are the warchest file's: rev_20260924_10_coa_warchest_item_templates.sql).
-- All four are vanity collectibles the client already knows, and none of the four
-- could work on a realm built from this tree:
--
--   * 101257 Scroll of Defense: Ashenvale and 101258 Scroll of Defense: Hillsbrad
--     Foothills had no item_template row anywhere in this repository - only the
--     visual placeholder mod-ascension-compat generates from Item.dbc;
--   * the four teleport spells they teach - 83126 (Ashenvale), 83128 (Hillsbrad
--     Foothills), 84288 (Orgrimmar) and 84289 (Stormwind) - had no
--     spell_target_position row anywhere either. Each one is
--     SPELL_EFFECT_TELEPORT_UNITS aimed at TARGET_DEST_DB (17), the destination a
--     spell reads from the world database, so without a row the scroll burns its
--     24 hour cooldown and leaves the player standing where they used it.
--
-- The destinations are the server's own .tele hub points, the same convention
-- rev_20260916_00_stone_of_retreat_destinations.sql uses for the Stones of Retreat,
-- and the two capital landings are the same rows that file already audited:
--
--   83126  Ashenvale            map 1  (1928.3400, -2165.9500,  93.7896)  .tele Ashenvale
--   83128  Hillsbrad Foothills  map 0  (-436.6570,  -581.2540,  53.5944)  .tele HillsbradFoothills
--   84288  Orgrimmar            map 1  (1629.8500, -4373.6400,  31.5573)  as Stone of Retreat: Orgrimmar (777000)
--   84289  Stormwind            map 0  (-8833.3800,  628.6280,  94.8162)  as Stone of Retreat: Stormwind (777003)
--
-- The pool rows below put the two Scrolls of Defense into Tiraxis's rotation at the
-- same 350-token tier as the Battle Horn, which is where a player finds them live.
--
-- Every statement here is idempotent - REPLACE for the rows that carry a key, and
-- REPLACE for the two item rows as well, so the file can be applied again whenever
-- it changes without the item table ever being deleted from.

REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES
(83126, 0, 1, 1928.3400, -2165.9500, 93.7896, 0.00, 0),  -- Scroll of Defense: Ashenvale
(83128, 0, 0, -436.6570, -581.2540, 53.5944, 0.00, 0),  -- Scroll of Defense: Hillsbrad Foothills
(84288, 0, 1, 1629.8500, -4373.6400, 31.5573, 0.00, 0),  -- Scroll of Retreat: Orgrimmar
(84289, 0, 0, -8833.3800, 628.6280, 94.8162, 0.00, 0);  -- Scroll of Retreat: Stormwind

REPLACE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) VALUES
(101257,15,0,-1,'Scroll of Defense: Ashenvale',295,6,64,0,1,0,0,0,-1,-1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.0,0.0,0,0.0,0.0,0,0,0,0,0,0,0,0,0,0,0.0,55884,0,-1,0.0,0,0,-1,83126,6,-1,0.0,86400000,0,-1,0,0,0,0.0,-1,0,-1,0,0,0,0.0,-1,0,-1,0,0,0,0.0,-1,0,-1,1,'Returns you to Ashenvale.',0,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0.0,0,0,0,'',0,0,0,0,0,12340),
(101258,15,0,-1,'Scroll of Defense: Hillsbrad Foothills',295,6,64,0,1,0,0,0,-1,-1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.0,0.0,0,0.0,0.0,0,0,0,0,0,0,0,0,0,0,0.0,55884,0,-1,0.0,0,0,-1,83128,6,-1,0.0,86400000,0,-1,0,0,0,0.0,-1,0,-1,0,0,0,0.0,-1,0,-1,0,0,0,0.0,-1,0,-1,1,'Returns you to Hillsbrad Foothills.',0,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0.0,0,0,0,'',0,0,0,0,0,12340);

REPLACE INTO `ethereal_bazaar_pool` (`item`, `extended_cost`, `price`, `band`) VALUES
(101257, 3015, 350, 0),
(101258, 3015, 350, 0);
