-- The green source line already says "Ascended Raid", so the name repeated it.
--
-- Only the 284 pieces are renamed: "Mythic" and "Sanctified" still carry information the tag does
-- not, and 264's tag is Heroic Raid rather than Sanctified. This does leave the 251 and 284 pieces
-- sharing a name, told apart by their item level and their source line, which is how the realm's
-- own difficulty variants already read.
UPDATE `item_template` SET `name` = TRIM(LEADING 'Ascended ' FROM `name`)
WHERE `entry` BETWEEN 992031 AND 992035 AND `name` LIKE 'Ascended %';

UPDATE `item_set_names` SET `name` = TRIM(LEADING 'Ascended ' FROM `name`)
WHERE `entry` BETWEEN 992031 AND 992035 AND `name` LIKE 'Ascended %';
