-- Woodchipper Dagger [53452] (Quality 2, Class WEAPON, ItemLevel 11) had DisenchantID = 0,
-- which Spell::CheckCast (SPELL_EFFECT_DISENCHANT) and Spell::EffectDisEnchant both require to be
-- non-zero before an item can be disenchanted at all - so the item could never be disenchanted
-- regardless of player skill (#7000). Every other Quality-2 weapon in ItemLevel 10-15 uses
-- DisenchantID = 21 (disenchant_loot_template bracket for that quality/ilevel range, e.g. entry
-- 816 "Small Hand Blade", same Quality/InventoryType/ItemLevel bucket). Assign the same bracket.
UPDATE `item_template` SET `DisenchantID` = 21 WHERE `entry` = 53452;
