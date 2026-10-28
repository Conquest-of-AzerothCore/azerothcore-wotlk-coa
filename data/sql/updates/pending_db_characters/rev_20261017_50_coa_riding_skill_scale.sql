-- Riding skill is Novice 50, then Apprentice 75, Journeyman 150, Expert 225, Artisan 300 and Extraordinary 375;
-- recalculate it from the highest rank each character knows
UPDATE `character_skills` AS `skills`
INNER JOIN (
    SELECT `guid`,
    MAX(CASE `spell`
        WHEN 33379 THEN 50
        WHEN 33388 THEN 75
        WHEN 33391 THEN 150
        WHEN 34090 THEN 225
        WHEN 34091 THEN 300
        WHEN 91774 THEN 375
    END) AS `riding`
    FROM `character_spell`
    WHERE `spell` IN (33379, 33388, 33391, 34090, 34091, 91774)
    GROUP BY `guid`
) AS `known` ON `known`.`guid` = `skills`.`guid`
SET `skills`.`value` = `known`.`riding`, `skills`.`max` = `known`.`riding`
WHERE `skills`.`skill` = 762;
