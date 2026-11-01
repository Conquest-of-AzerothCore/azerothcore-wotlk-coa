-- Worldforged Travel Sack pickups (gameobject_loot_template rows, mod-worldforged-pickups data)
-- hand out items that never had an item_template row, so the chest's loot window opens empty:
-- Entry 9900024 (Westfall "Forgotten Sack", comment "Worldforged Travel Sack | LootCollector NEW
-- Westfall", rev_20261014_95_worldforged_lootcollector_alignment.sql:31,79) loots item 451107;
-- Entries 95612/95812 (the Mulgore/Red Cloud Mesa "Travel Sack" namesake pickups,
-- 2026_09_16_00_worldforged_pickups.sql:1208,1956,2118, comment "namesake object name == item
-- name") loot item 450510. #10029.
-- class/subclass/SoundOverrideSubclass/Material/displayid/InventoryType come straight from the
-- client's own Item.dbc (450510: ClassID 1, SubclassID 0, SoundOverrideSubclassID -1, Material 8,
-- DisplayInfoID 15320, InventoryType 18; 451107: ClassID 1, SubclassID 0, SoundOverrideSubclassID
-- -1, Material 8, DisplayInfoID 138737, InventoryType 18 - both regular 18=INVTYPE_BAG containers,
-- matching ObjectMgr::LoadItemTemplates's DBC enforcement). Names follow the pickups' own
-- documented convention ("namesake object name == item name"): 450510 takes gameobject 95612's
-- name "Travel Sack"; 451107 takes gameobject 9900024's name "Forgotten Sack". The remaining
-- fields (Quality/Flags/FlagsExtra/BuyPrice/SellPrice/ItemLevel/RequiredLevel/maxcount/stackable/
-- bonding/ContainerSlots) are not DBC fields; they reuse the single most common combo among every
-- other class=1/subclass=0 (regular bag) item_template row sharing ContainerSlots=10 (9 of 18
-- such rows, e.g. "Large Blue Sack"/"Large Rucksack"/"Large Green Sack": Quality 1, Flags 0,
-- FlagsExtra 0, BuyPrice 10000, SellPrice 2500, ItemLevel 25 (18 of 18), RequiredLevel 0 (18 of
-- 18), maxcount 0, stackable 1, bonding 0) rather than invented values; ContainerSlots=10 matches
-- the reporter's own "should be 10 slot bag" description and is itself the second most common
-- slot count among sibling bags.
INSERT IGNORE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`,
    `Quality`, `Flags`, `FlagsExtra`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `ContainerSlots`, `bonding`, `Material`, `description`)
VALUES
(450510, 1, 0, -1, 'Travel Sack', 15320, 1, 0, 0, 10000, 2500, 18, -1, -1, 25, 0, 0, 1, 10, 0, 8, ''),
(451107, 1, 0, -1, 'Forgotten Sack', 138737, 1, 0, 0, 10000, 2500, 18, -1, -1, 25, 0, 0, 1, 10, 0, 8, '');
