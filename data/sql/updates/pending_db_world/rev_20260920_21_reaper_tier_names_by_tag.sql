-- The green source line is what says which raid a piece came from, so the name does not
-- repeat it: a piece read "Mythic Frostbitten Helm of the Risen Nightmare" above a green
-- "Mythic". Sanctified stays, because that is the piece's own name in this tier rather than
-- a difficulty the tag already carries.
UPDATE `item_template` SET `name` = TRIM(LEADING 'Mythic ' FROM `name`)
WHERE `entry` BETWEEN 992021 AND 992025 AND `name` LIKE 'Mythic %';

UPDATE `item_set_names` SET `name` = TRIM(LEADING 'Mythic ' FROM `name`)
WHERE `entry` BETWEEN 992021 AND 992025 AND `name` LIKE 'Mythic %';

-- The realm's own tag for that difficulty is "Mythic Raid", which 1966 items carry. A bare
-- "Mythic" is what 13446 items of every other kind use, so the 277 pieces read as if they
-- had come from anywhere.
UPDATE `item_template` SET `description` = '@Mythic Raid@'
WHERE `entry` BETWEEN 992021 AND 992025 AND `description` = '@Mythic@';

-- The 251 pieces are the entry difficulty. They carried the Heroic Raid tag, which belongs
-- to the 264 ones, so both read as the same raid; with no tag the tooltip shows no source
-- line at all, which is what the entry difficulty should look like.
UPDATE `item_template` SET `description` = ''
WHERE `entry` BETWEEN 992001 AND 992005 AND `description` = '@Heroic Raid@';
