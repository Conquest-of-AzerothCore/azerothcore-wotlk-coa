-- Potion of Experience (135060) kept the spell and requirements of the Potion of Petrification (13506)
-- row it was copied from; give it the same use as Potion of Experience (818046).
UPDATE `item_template` SET
    `SellPrice` = 0, `ItemLevel` = 0, `RequiredLevel` = 0, `spellid_1` = 818046, `spellppmRate_1` = 0,
    `spellcooldown_1` = 1500, `spellcategory_1` = 133, `spellcategorycooldown_1` = 1500
WHERE `entry` = 135060;
