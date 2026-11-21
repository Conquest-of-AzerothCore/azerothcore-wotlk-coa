START TRANSACTION;

-- Tier 3 Armor starts two item levels above the top of the Heroic AQ40 armor band.
-- Preserve each piece's stat distribution and the existing room between difficulty tiers.
CREATE TEMPORARY TABLE `_coa_naxx_tier3_armor` AS
SELECT `target`.`entry`, `page`.`old_ilvl`, `page`.`new_ilvl`
FROM (
    SELECT 91000009 AS `vendor`, 86 AS `old_ilvl`, 88 AS `new_ilvl`
    UNION ALL SELECT 91000010, 90, 92
    UNION ALL SELECT 91000011, 95, 97
    UNION ALL SELECT 91000012, 99, 101
) AS `page`
JOIN `npc_vendor` AS `offer` ON `offer`.`entry` = `page`.`vendor`
JOIN `item_template` AS `armor` ON `armor`.`entry` = `offer`.`item`
JOIN `item_template` AS `target` ON (
    `target`.`entry` = `armor`.`entry` OR
    (`target`.`entry` = `armor`.`entry` + 6000000 AND `target`.`name` LIKE 'Bloodforged %'))
WHERE `armor`.`class` = 4 AND `armor`.`ItemSet` <> 0 AND `armor`.`RequiredLevel` = 60
    AND `target`.`ItemLevel` = `page`.`old_ilvl`;

UPDATE `item_template` AS `item`
JOIN `_coa_naxx_tier3_armor` AS `budget` ON `budget`.`entry` = `item`.`entry`
SET `item`.`ItemLevel` = `budget`.`new_ilvl`,
    `item`.`stat_value1` = ROUND(`item`.`stat_value1` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value2` = ROUND(`item`.`stat_value2` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value3` = ROUND(`item`.`stat_value3` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value4` = ROUND(`item`.`stat_value4` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value5` = ROUND(`item`.`stat_value5` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value6` = ROUND(`item`.`stat_value6` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value7` = ROUND(`item`.`stat_value7` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value8` = ROUND(`item`.`stat_value8` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value9` = ROUND(`item`.`stat_value9` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`stat_value10` = ROUND(`item`.`stat_value10` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`armor` = ROUND(`item`.`armor` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`block` = ROUND(`item`.`block` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`holy_res` = ROUND(`item`.`holy_res` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`fire_res` = ROUND(`item`.`fire_res` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`nature_res` = ROUND(`item`.`nature_res` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`frost_res` = ROUND(`item`.`frost_res` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`shadow_res` = ROUND(`item`.`shadow_res` * `budget`.`new_ilvl` / `budget`.`old_ilvl`),
    `item`.`arcane_res` = ROUND(`item`.`arcane_res` * `budget`.`new_ilvl` / `budget`.`old_ilvl`);

DROP TEMPORARY TABLE `_coa_naxx_tier3_armor`;

COMMIT;
