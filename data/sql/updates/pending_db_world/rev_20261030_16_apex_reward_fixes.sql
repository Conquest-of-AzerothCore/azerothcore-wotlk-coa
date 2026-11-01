-- The Skin-Peeler was class 15 subclass 4 (Misc/Junk) with spell 92865, which does not exist,
-- so it was a cosmetic. Make it a real one-hand dagger with the skinning equip bonus that
-- Finkle's Skinner uses (spell 16718, trigger 1), and make the diploma consumed on use.
UPDATE `item_template`
SET `class` = 2, `subclass` = 15, `InventoryType` = 13, `ItemLevel` = 60, `RequiredLevel` = 58,
    `Quality` = 4, `dmg_min1` = 45, `dmg_max1` = 84, `delay` = 1800, `dmg_type1` = 0,
    `spellid_1` = 16718, `spelltrigger_1` = 1, `spellcharges_1` = 0,
    `bonding` = 1, `stat_type1` = 3, `stat_value1` = 12, `stat_type2` = 7, `stat_value2` = 8
WHERE `entry` = 190191;

UPDATE `item_template`
SET `spellcharges_1` = 1
WHERE `entry` = 1009300;
