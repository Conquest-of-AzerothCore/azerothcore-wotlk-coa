-- Bloody Mark of War 1235070 ("Use: Awards 1000 Runes of Ascension.") casts the dummy spell 413117, which pays
-- nothing by itself. Bind it to the Rune of Ascension pouch script, which pays the 1000 runes and spends the mark.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_rune_pouch' WHERE `entry` = 1235070;
