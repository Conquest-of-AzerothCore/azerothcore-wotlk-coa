-- Tin and Copper Mark of War (1303552, 1201001) cast the dummy spells 413113/413115 ("Awards 10/100 Runes of
-- Ascension."), which pay nothing by themselves, so a right click did nothing. Bind them to the Rune of Ascension pouch
-- script like the Bronze, Silver, Golden and Bloody marks.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_rune_pouch' WHERE `entry` IN (1303552, 1201001) AND `ScriptName` = '';
