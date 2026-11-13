-- Venomancers who prestiged before #10453 was fixed kept Wasp Form (805141) without Venomwing Form (520307);
-- the Book of Ascension then showed Venomwing as known and refused to sell it. Forget the orphaned Wasp Form
-- so both can be bought again in order (Venomwing at 16, Wasp Form at 60).
DELETE `wasp` FROM `character_spell` AS `wasp`
INNER JOIN `characters` AS `c` ON `c`.`guid` = `wasp`.`guid` AND `c`.`class` = 29
INNER JOIN `character_settings` AS `prestige` ON `prestige`.`guid` = `wasp`.`guid`
    AND `prestige`.`source` = 'core.coa_prestige'
    AND CAST(SUBSTRING_INDEX(TRIM(`prestige`.`data`), ' ', 1) AS UNSIGNED) > 0
LEFT JOIN `character_spell` AS `venomwing` ON `venomwing`.`guid` = `wasp`.`guid` AND `venomwing`.`spell` = 520307
WHERE `wasp`.`spell` = 805141 AND `venomwing`.`guid` IS NULL;
