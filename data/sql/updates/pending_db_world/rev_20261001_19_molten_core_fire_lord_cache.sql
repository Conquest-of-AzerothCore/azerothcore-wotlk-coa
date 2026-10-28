-- Cache of the Fire Lord (2400040) is openable per player memory (no recorded data anywhere,
-- see diag-K-firelord-cache.md): one random piece of equippable gear from the killed raid's OWN
-- difficulty loot. On Mythic/Ascended it already drops at 100% from Ragnaros (211502/311502);
-- it did not exist at all on Normal/Heroic (11502/111502), so it is added there too, at the same
-- 100% guaranteed rate and GroupId 0 used by the Mythic/Ascended rows, without touching the
-- existing GroupId 1-8 rolls on those two rows.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (11502, 111502) AND `Item` = 2400040;
INSERT INTO `creature_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(11502, 2400040, 0, 100, 0, 1, 0, 1, 1, 'Ragnaros - Cache of the Fire Lord'),
(111502, 2400040, 0, 100, 0, 1, 0, 1, 1, 'Ragnaros - Cache of the Fire Lord');

-- The cache's own on-use spell (93461) is a bare dummy shared with 50+ unrelated caches fleet-wide
-- (diag-K-firelord-cache.md): it carries no content of its own. coa_mc_fire_lord_cache_pool is the
-- data-driven pool the ItemScript (AscensionFireLordCache.cpp) reads at open time, one row per
-- (RaidDifficulty, ItemEntry): built from the *effective* creature_loot_template of the nine MC
-- bosses plus Ragnaros, at each of the four raid difficulties (0 Normal/base entry, 1 Heroic
-- /+100000, 2 Mythic /+200000, 3 Ascended /+300000 - the same offsets coa_mc_token_loot and
-- FlexLoot.cpp already use), resolving `Reference` chains into reference_loot_template recursively
-- instead of hard-coding any item id.
--
-- Excluded while resolving, so no extra per-item filtering is required beyond item_template.class:
--   - every Tier 1 token reference (4090011-4090057, see coa_mc_token_loot) - tier tokens, not gear;
--   - reference_loot_template 34002, AzerothCore's own generic "classic BoE world drop" pool reused
--     by thousands of unrelated creatures server-wide (confirmed live: it also attaches to non-MC
--     creature entries 6109/14887-14890) - real gear, but not Molten Core's own itemization, so
--     kept out of "the raid's own loot" on purpose.
-- Kept in, by the plain item_template.class filter below, with no manual id list:
--   - `class` 0 (consumables, including the two other unrelated "Cache of the Fire Lord"-named
--     items 1400024/1400040 and Personal Cache 1170083, itself class 15), 7 (trade goods: Sulfuron
--     Ingot, Eye of Sulfuras), 10/12 (quest-chain rewards/items), 15 (sigils, Raider's Commendation,
--     the non-equippable "Molten <Slot>" class-15 placeholder items - confirmed live: InventoryType
--     0, zero stats/armor - and Bindings of the Windseeker) are all excluded, since none of them is
--     class 2 or 4;
--   - `class` 2 (Weapon) / 4 (Armor, including rings/trinkets/cloaks/necks) items with a real
--     equip slot (InventoryType != 0) pass through - on Normal/Heroic this is the raid's full
--     classic itemization (Cloak of the Shrouded Mists, Band of Accuria, Bonereaver's Edge, Drillborer
--     Disk, Talisman of Binding Shard, Band of Sulfuras, ...); on Mythic/Ascended this fork's loot
--     restructure currently keeps only Talisman of Binding Shard (Baron Geddon) and Band of Sulfuras
--     (Ragnaros) as class 2/4 drops - a thin but accurate reflection of the effective tables, not
--     invented or padded; re-balancing Mythic/Ascended MC gear itself is out of this task's scope.
CREATE TABLE IF NOT EXISTS `coa_mc_fire_lord_cache_pool` (
    `RaidDifficulty` TINYINT UNSIGNED NOT NULL,
    `ItemEntry` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`RaidDifficulty`, `ItemEntry`)
) ENGINE=InnoDB;

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

-- AscensionFireLordCache.cpp's item_ascension_fire_lord_cache ItemScript only ever runs for the
-- item template(s) that name it here - the shared dummy spell 93461 and its 50+ other caches are
-- untouched.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_fire_lord_cache' WHERE `entry` = 2400040;
