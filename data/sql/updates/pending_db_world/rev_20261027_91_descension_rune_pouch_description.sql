-- rev_20260921_10 renamed the Rune of Descension Pouch (509894) but missed its stored description, which still
-- read "... Runes of Ascension ..." (#4754). Confirmed against the live item_template row before this change.
UPDATE `item_template` SET `description` = REPLACE(`description`, 'Ascension', 'Descension')
    WHERE `entry` = 509894 AND `description` LIKE '%Ascension%';
