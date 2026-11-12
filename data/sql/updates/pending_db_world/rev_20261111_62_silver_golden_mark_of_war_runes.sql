-- Silver and Golden Mark of War (#11849): their dummy spells 413116 and 413117 award 250 and 1000 Runes of Ascension.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_rune_pouch' WHERE `entry` IN (1201002, 1201003);
