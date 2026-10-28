-- Battle Horn (898070): the item, restored.
--
-- The client knows it - Item.dbc row 898070, ItemAddon row 363920 naming it
-- "Battle Horn" with the description "Blast a blaring horn, attracting enemies
-- within 30 yards.", display 26987, and VanityCollection entry 68493 teaching
-- spell 898070 - and the live realm's own vendor sells it from Tiraxis's rotation,
-- which is why mod-ethereal-bazaar's generated pool already carries
--
--     (898070,3015,350,0)
--
-- but no item_template row for it existed anywhere in this repository. On a realm
-- built from this tree that pool row is dangling: Item::CreateItem() returns null
-- for 898070, so the rotation slot comes up empty and the item cannot be granted,
-- mailed or bought.
--
-- Nothing else about the item needs a server change. Spell 898070 is defined by the
-- client's own Spell.dbc as SPELL_EFFECT_THREAT against every enemy within 30 yd of
-- the caster (radius 10) plus a DUMMY effect, and it also hands the character the
-- horn ability: the item's second spell slot teaches 898070 through the ordinary
-- 55884 learn-item path.
--
-- The row below is what a repack database carries for the item, field for field, so
-- the repack and the repository stop disagreeing. It is written as REPLACE, which
-- replaces the row with this exact entry - the same thing as deleting it and
-- inserting it again - so the statement is idempotent and nothing here ever touches
-- another item. Idempotent: the file is applied again whenever it changes.

REPLACE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) VALUES
(898070,0,0,-1,'Battle Horn',26987,6,0,0,1,0,0,0,-1,-1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.0,0.0,0,0.0,0.0,0,0,0,0,0,0,0,0,0,0,0.0,55884,0,-1,0.0,0,0,0,898070,6,-1,0.0,120000,0,0,0,0,0,0.0,-1,0,-1,0,0,0,0.0,-1,0,-1,0,0,0,0.0,-1,0,-1,3,'Blast a blaring horn, attracting enemies within 30 yards.',0,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0.0,0,0,0,'',0,0,0,0,0,NULL);
