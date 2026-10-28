-- coa_mc_fire_lord_cache_pool (rev_20261001_19) is built by a CTE scanning the *effective*
-- creature_loot_template at apply time. rev_20261001_40 (real T1/T2 tokens) and rev_20261001_41
-- (scaled non-set epics/case pools) both sort after _19 and add/replace rows on the same boss
-- entries, so the pool built by _19 was computed before those rows existed: on a fresh import the
-- Mythic/Ascended pools ended up with only the 2 pre-existing class 2/4 gear pieces (Talisman of
-- Binding Shard, Band of Sulfuras), not the fuller set _40/_41 restore. This file re-runs the exact
-- same CTE as _19, unchanged, once more after _40/_41 so the pool reflects the final effective
-- loot tables. Idempotent: safe to re-run, and a no-op if ever reordered ahead of _40/_41.
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
    SELECT `RaidDifficulty`, `CreatureEntry`, 'creature' FROM `boss_entry`
    UNION ALL
    SELECT `ls`.`RaidDifficulty`, `clt`.`Reference`, 'reference'
    FROM `loot_scan` `ls`
    JOIN `creature_loot_template` `clt` ON `ls`.`TemplateSource` = 'creature' AND `clt`.`Entry` = `ls`.`TemplateEntry`
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
JOIN `creature_loot_template` `clt` ON `ls`.`TemplateSource` = 'creature' AND `clt`.`Entry` = `ls`.`TemplateEntry` AND `clt`.`Reference` = 0
JOIN `item_template` `it` ON `it`.`entry` = `clt`.`Item`
WHERE `it`.`class` IN (2, 4) AND `it`.`InventoryType` != 0
UNION
SELECT DISTINCT `ls`.`RaidDifficulty`, `it`.`entry`
FROM `loot_scan` `ls`
JOIN `reference_loot_template` `rlt` ON `ls`.`TemplateSource` = 'reference' AND `rlt`.`Entry` = `ls`.`TemplateEntry` AND `rlt`.`Reference` = 0
JOIN `item_template` `it` ON `it`.`entry` = `rlt`.`Item`
WHERE `it`.`class` IN (2, 4) AND `it`.`InventoryType` != 0;
