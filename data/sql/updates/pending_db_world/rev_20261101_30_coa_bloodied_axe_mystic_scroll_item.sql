-- Bloodied Axe (gameobject 93008, Duskwood) loots item 201579 ("Mystic Scroll: Brutal Execution",
-- gameobject_loot_template entry 93008 at modules/mod-worldforged-pickups/data/sql/db-world/2026_09_23_06_worldforged_recorded_heights.sql:324-325)
-- but item_template never had a row for 201579: the loot roll produces nothing, the loot window
-- opens empty and the chest never clears its sparkle. #9764, #9769 (duplicate).
-- class/subclass/SoundOverrideSubclass/Material/displayid/InventoryType come straight from the
-- client's own Item.dbc record 201579 (ClassID 0, SubclassID 6, SoundOverrideSubclassID -1,
-- Material 8, DisplayInfoID 138380, InventoryType 0): ObjectMgr::LoadItemTemplates enforces every
-- one of those against the DBC and silently overwrites a mismatch, which is what rejected the
-- data file's own displayid 169164/Material 0 convention for this entry. Quality/Flags/BuyPrice
-- are not DBC fields; they reuse rev_20261005_01_coa_seasonal_mystic_scrolls.sql's single most
-- common combo for a quality-4 scroll (134217792/300000, 49 of 1560 rows) rather than invented
-- values. The harvested flavor-text reference id that file's other rows carry is not derivable
-- without the live realm's own item dump, so description is left empty instead of guessing one.
INSERT IGNORE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `Material`, `description`) VALUES
(201579, 0, 6, -1, 'Mystic Scroll: Brutal Execution', 138380, 4, 134217792, 0, 300000, 1, 0, 512, -1, 60, 0, 0, 1, 0, 8, '');
