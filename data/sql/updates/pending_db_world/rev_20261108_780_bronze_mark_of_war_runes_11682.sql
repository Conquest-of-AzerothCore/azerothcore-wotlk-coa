-- Bronze Mark of War 1303551 ("Awards 50 Runes of Ascension.") casts the dummy spell 413114, which pays nothing by
-- itself, so a right click did nothing. Bind it to the Rune of Ascension pouch script, which pays 50 runes and spends
-- the mark.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_rune_pouch' WHERE `entry` = 1303551 AND `ScriptName` = '';
