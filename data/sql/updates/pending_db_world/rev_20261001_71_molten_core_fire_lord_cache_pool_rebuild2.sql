-- rev_20261001_70 moved every boss's non-set epic gear rows out of creature_loot_template
-- (GroupId 2/3/4 on the base entries, GroupId 10/11 on the scaled entries) into the new
-- coa_mc_item_pool table, so rev_20261001_42's recursive-CTE rebuild of
-- coa_mc_fire_lord_cache_pool (itself scanning creature_loot_template/reference_loot_template)
-- would otherwise lose that gear and shrink below its previous size on every difficulty. This
-- migration re-runs the same CTE once more, late, and unions in coa_mc_item_pool's own rows
-- (already filtered to class 2/4 gear by construction, common-pool rows at CreatureEntry = 0
-- applied once per difficulty, boss-own rows applied per boss) so the cache pool keeps drawing
-- from the same gear, just relocated. Idempotent: safe to re-run, and a no-op if ever reordered
-- ahead of rev_20261001_70.
--
-- `TemplateSource`'s anchor literal is `'creature1'` (9 chars), not the shorter `'creature'`:
-- MySQL infers a recursive CTE column's type from the anchor member alone, and the recursive
-- member's `'reference'` literal (9 chars) does not fit an 8-char-inferred column, failing with
-- "Data too long for column 'TemplateSource'" the first time a real reference chain is walked.
-- Padding the anchor's own literal to the same length sidesteps the bug without a CAST.
DELETE FROM `coa_mc_fire_lord_cache_pool`;
INSERT INTO `coa_mc_fire_lord_cache_pool` (`RaidDifficulty`, `ItemEntry`)
WITH RECURSIVE `boss_entry` (`RaidDifficulty`, `CreatureEntry`) AS (
    SELECT 0, 11502 UNION ALL SELECT 0, 11982 UNION ALL SELECT 0, 11988 UNION ALL
    SELECT 0, 12056 UNION ALL SELECT 0, 12057 UNION ALL SELECT 0, 12098 UNION ALL
    SELECT 0, 12118 UNION ALL SELECT 0, 12259 UNION ALL SELECT 0, 12264 UNION ALL SELECT 0, 12018
    UNION ALL
    SELECT 1, 111502 UNION ALL SELECT 1, 111982 UNION ALL SELECT 1, 111988 UNION ALL
    SELECT 1, 112056 UNION ALL SELECT 1, 112057 UNION ALL SELECT 1, 112098 UNION ALL
    SELECT 1, 112118 UNION ALL SELECT 1, 112259 UNION ALL SELECT 1, 112264 UNION ALL SELECT 1, 112018
    UNION ALL
    SELECT 2, 211502 UNION ALL SELECT 2, 211982 UNION ALL SELECT 2, 211988 UNION ALL
    SELECT 2, 212056 UNION ALL SELECT 2, 212057 UNION ALL SELECT 2, 212098 UNION ALL
    SELECT 2, 212118 UNION ALL SELECT 2, 212259 UNION ALL SELECT 2, 212264 UNION ALL SELECT 2, 212018
    UNION ALL
    SELECT 3, 311502 UNION ALL SELECT 3, 311982 UNION ALL SELECT 3, 311988 UNION ALL
    SELECT 3, 312056 UNION ALL SELECT 3, 312057 UNION ALL SELECT 3, 312098 UNION ALL
    SELECT 3, 312118 UNION ALL SELECT 3, 312259 UNION ALL SELECT 3, 312264 UNION ALL SELECT 3, 312018
),
`loot_scan` (`RaidDifficulty`, `TemplateEntry`, `TemplateSource`) AS (
    SELECT `RaidDifficulty`, `CreatureEntry`, 'creature1' FROM `boss_entry`
    UNION ALL
    SELECT `ls`.`RaidDifficulty`, `clt`.`Reference`, 'reference'
    FROM `loot_scan` `ls`
    JOIN `creature_loot_template` `clt` ON `ls`.`TemplateSource` = 'creature1' AND `clt`.`Entry` = `ls`.`TemplateEntry`
    WHERE `clt`.`Reference` != 0 AND `clt`.`Reference` != 34002
      AND `clt`.`Reference` NOT BETWEEN 4090011 AND 4090057
    UNION ALL
    SELECT `ls`.`RaidDifficulty`, `rlt`.`Reference`, 'reference'
    FROM `loot_scan` `ls`
    JOIN `reference_loot_template` `rlt` ON `ls`.`TemplateSource` = 'reference' AND `rlt`.`Entry` = `ls`.`TemplateEntry`
    WHERE `rlt`.`Reference` != 0 AND `rlt`.`Reference` != 34002
      AND `rlt`.`Reference` NOT BETWEEN 4090011 AND 4090057
)
SELECT DISTINCT `ls`.`RaidDifficulty`, `it`.`entry`
FROM `loot_scan` `ls`
JOIN `creature_loot_template` `clt` ON `ls`.`TemplateSource` = 'creature1' AND `clt`.`Entry` = `ls`.`TemplateEntry` AND `clt`.`Reference` = 0
JOIN `item_template` `it` ON `it`.`entry` = `clt`.`Item`
WHERE `it`.`class` IN (2, 4) AND `it`.`InventoryType` != 0
UNION
SELECT DISTINCT `ls`.`RaidDifficulty`, `it`.`entry`
FROM `loot_scan` `ls`
JOIN `reference_loot_template` `rlt` ON `ls`.`TemplateSource` = 'reference' AND `rlt`.`Entry` = `ls`.`TemplateEntry` AND `rlt`.`Reference` = 0
JOIN `item_template` `it` ON `it`.`entry` = `rlt`.`Item`
WHERE `it`.`class` IN (2, 4) AND `it`.`InventoryType` != 0
UNION
SELECT `RaidDifficulty`, `ItemEntry` FROM `coa_mc_item_pool`;
