-- ============================================================================
-- Conquest of AzerothCore / mod-manastorm-endless
-- Black Temple Manastorm cache reconstruction - reference-pool model
-- Updated 2026-09-25 after Manastorm cache archaeology
--
-- Reconstructs:
--   1288068  Manastorm Cache: Black Temple
--   1288071  Manastorm Cache: Heroic Black Temple
--   1289071  Manastorm Cache: Mythic Black Temple
--
-- SOURCE MODEL
-- ------------
-- Cache-family membership comes from the recovered Ascension item_template
-- descriptions. Raid membership comes from the current Ascension AtlasLoot TBC
-- encounter tables, with non-equipment rows removed. Difficulty variants are
-- resolved from item_template through the recovered @Heroic Raid@ / @Mythic Raid@
-- markers. TBC Mythic dungeon families are restricted to real AtlasLoot TBC
-- dungeon item names and the @Mythic N@ variants.
--
-- IMPLEMENTATION MODEL
-- --------------------
-- This version supersedes the earlier flattened physical-cache layout.
--
-- Physical cache rows now choose a FAMILY by reference:
--   * positive Chance rows = optional "Chance to contain" families
--   * Chance=0 row         = advertised "Contains" fallback family
--
-- The referenced family contains equal-chance candidate gear. The
-- mod-manastorm-endless GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED selector then
-- personalizes the winning gear item for the opener. SQL therefore owns WHAT can
-- appear and the family probabilities; C++ owns HOW one item is selected inside
-- the chosen family.
--
-- IMPORTANT CHANCE NOTE
-- ---------------------
-- Ascension's original optional-family percentages were not recovered.
-- 10% per optional family is a deliberate CoA reconstruction value and can be
-- rebalanced later without changing C++.
--
SET @MS_OPTIONAL_FAMILY_PCT := 10.0;
--
-- With the default 10%:
--   1288068: 3 optional families = 30% optional / 70% primary fallback
--   1288071: 3 optional families = 30% optional / 70% primary fallback
--   1289071: 4 optional families = 40% optional / 60% primary fallback
--
-- Keep @MS_OPTIONAL_FAMILY_PCT <= 25.0 while Mythic BT has four optional
-- families in the same GroupId.
--
-- Reserved Manastorm reference-loot namespace used by this migration:
--   9001001 Normal Hyjal
--   9001002 Heroic Hyjal
--   9001003 Mythic Hyjal
--   9001010 Normal Black Temple
--   9001011 Heroic Black Temple
--   9001012 Mythic Black Temple
--   9001021 Heroic Sunwell
--   9001031 TBC Mythic Dungeon 11-20
--   9001032 TBC Mythic Dungeon 21-30
--   9001033 TBC Mythic Dungeon 31-40
--   9001041 Normal BT + Normal Hyjal fallback
--   9001042 Heroic BT + Heroic Hyjal fallback
--
-- This script replaces ONLY the three BT physical-cache item_loot_template rows
-- plus the reserved reference pools above. It does not alter item_template,
-- Manastorm brackets, cache pity/chance, mail delivery, Treasure Keeper, or
-- Ascended Black Temple.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0) Source base pools
-- ---------------------------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_hyjal_normal`;
CREATE TEMPORARY TABLE `tmp_ms_hyjal_normal`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_hyjal_normal` (`item`) VALUES
(12311), (30861), (30862), (30863), (30864), (30865), (30866), (30868), (30869), (30870), (30871), (30872),
(30873), (30891), (30914), (12306), (12307), (30874), (30878), (30879), (30880), (30881), (30882), (30883),
(30884), (30885), (30886), (30887), (30888), (30916), (30919), (12308), (12309), (30892), (30896), (30897),
(30899), (30901), (30917), (12310), (30889), (30893), (30894), (30895), (30898), (30900), (30915), (30918),
(12312), (12313), (12386), (12387), (30902), (30903), (30904), (30905), (30906), (30907), (30908), (30909),
(30910), (30911), (30912), (30913), (12388), (12389), (15041), (15828), (15830), (15831), (15834), (15835),
(15836), (15838), (15839), (15840), (15896), (15898), (15899);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_bt_normal`;
CREATE TEMPORARY TABLE `tmp_ms_bt_normal`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_bt_normal` (`item`) VALUES
(32264), (32265), (32266), (32268), (32270), (32273), (32275), (32276), (32278), (32279), (32361), (32513),
(32332), (32333), (32345), (32346), (32347), (32350), (32351), (32352), (32353), (32354), (32362), (32517),
(32271), (32280), (32323), (32324), (32325), (32327), (32328), (32329), (32349), (32507), (32510), (32512),
(32232), (32234), (32236), (32238), (32239), (32240), (32241), (32242), (32243), (32245), (32248), (32377),
(32237), (32247), (32250), (32251), (32252), (32253), (32254), (32255), (32256), (32258), (32259), (32260),
(32261), (32262), (32235), (32336), (32363), (32374), (32375), (32471), (32483), (32496), (32497), (32500),
(32501), (32505), (32521), (32524), (32525), (32263), (32365), (32366), (32367), (32369), (32370), (12571),
(32269), (32334), (32335), (32337), (32338), (32339), (32340), (32341), (32342), (32343), (32344), (32348),
(32326), (32331), (32373), (32376), (32518), (32519);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_sunwell_normal`;
CREATE TEMPORARY TABLE `tmp_ms_sunwell_normal`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_sunwell_normal` (`item`) VALUES
(11523), (34176), (34177), (34178), (34179), (34180), (34181), (34381), (34164), (34165), (34166), (34167),
(34168), (34169), (34170), (34382), (34384), (34386), (34182), (34184), (34185), (34186), (34188), (34352),
(34383), (34385), (34241), (34242), (34243), (34244), (34245), (34247), (34329), (34331), (34332), (34333),
(34335), (34336), (34337), (34339), (34340), (34341), (34342), (34343), (34344), (34345), (34400), (34401),
(34402), (34403), (34404), (34405), (34406), (35282), (35283), (35284), (35290), (35291), (35292), (34211),
(34212), (34213), (34214), (34215), (34216), (34228), (34229), (34230), (34231), (34232), (34233), (34234),
(34240), (34394), (34395), (34396), (34397), (34398), (34399), (34408), (34427), (34428), (34429), (34430),
(34189), (34190), (34192), (34193), (34194), (34195), (34196), (34197), (34198), (34199), (34202), (34203),
(34204), (34205), (34206), (34208), (34209), (34210), (34388), (34389), (34390), (34391), (34392), (34393);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_tbc_dungeon_base`;
CREATE TEMPORARY TABLE `tmp_ms_tbc_dungeon_base`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_tbc_dungeon_base` (`item`) VALUES
(24020), (24021), (24022), (24023), (24024), (24069), (24073), (24090), (24091), (24094), (24096), (24356),
(24357), (24360), (24361), (24362), (24363), (24364), (24365), (24366), (24376), (24378), (24379), (24380),
(24381), (24384), (24385), (24386), (24387), (24388), (24389), (24390), (24391), (24392), (24393), (24394),
(24395), (24396), (24397), (24398), (24413), (24450), (24451), (24452), (24453), (24454), (24455), (24456),
(24457), (24458), (24459), (24460), (24461), (24462), (24463), (24464), (24465), (24466), (24481), (25964),
(26055), (27408), (27409), (27410), (27411), (27412), (27413), (27414), (27415), (27416), (27474), (27475),
(27508), (27509), (27510), (27517), (27518), (27519), (27520), (27521), (27524), (27525), (27526), (27527),
(27528), (27529), (27531), (27533), (27534), (27535), (27536), (27537), (27538), (27540), (27631), (27737),
(27738), (27783), (27784), (27787), (27789), (27790), (27791), (27792), (27793), (27794), (27795), (27797),
(27799), (27801), (27802), (27804), (27805), (27806), (27839), (27868), (27873), (27874), (27876), (27877),
(27878), (27937), (27977), (27987), (27988), (27993), (27994), (27995), (27996), (28033), (28034), (28184),
(28185), (28186), (28187), (28188), (28189), (28190), (28192), (28193), (28194), (28203), (28206), (28207),
(28248), (28249), (28250), (28251), (28252), (28268), (30705), (30707), (30708), (30709), (30710), (32769),
(32778), (32779), (32780), (32781), (34601), (34602), (34603), (34604), (34605), (34606), (34607), (34608),
(34609), (34610), (34611), (34612), (34613), (34614), (34615), (34616), (34625), (34700), (34703), (34789),
(34791), (34792), (34799), (34807), (34808), (34809), (34810), (203224), (211728), (212654), (212713), (212826),
(213383), (215448), (217674), (218255), (218298), (219576), (222146), (222844), (223076), (223128), (231828), (231871),
(232061), (232104), (232147), (240379), (241500), (241543), (241661), (241704), (241747), (241790), (241833), (241876),
(241919), (242509), (242552), (242638), (242724), (242767), (242853), (244286), (244958), (245159), (245878), (245962);

-- ---------------------------------------------------------------------------
-- 1) Resolve exact raid difficulty variants from item_template.
--    Prefix matching is intentional because a few rows append extra text after
--    the difficulty marker, e.g. "@Heroic Raid@ Keep Off".
-- ---------------------------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_hyjal_heroic`;
CREATE TEMPORARY TABLE `tmp_ms_hyjal_heroic`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_hyjal_heroic` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_hyjal_normal` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
 AND v.`Quality` = b.`Quality`
WHERE v.`description` LIKE '@Heroic Raid@%';

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_hyjal_mythic`;
CREATE TEMPORARY TABLE `tmp_ms_hyjal_mythic`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_hyjal_mythic` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_hyjal_normal` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
 AND v.`Quality` = b.`Quality`
WHERE v.`description` LIKE '@Mythic Raid@%';

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_bt_heroic`;
CREATE TEMPORARY TABLE `tmp_ms_bt_heroic`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_bt_heroic` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_bt_normal` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
 AND v.`Quality` = b.`Quality`
WHERE v.`description` LIKE '@Heroic Raid@%';

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_bt_mythic`;
CREATE TEMPORARY TABLE `tmp_ms_bt_mythic`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_bt_mythic` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_bt_normal` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
 AND v.`Quality` = b.`Quality`
WHERE v.`description` LIKE '@Mythic Raid@%';

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_sunwell_heroic`;
CREATE TEMPORARY TABLE `tmp_ms_sunwell_heroic`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_sunwell_heroic` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_sunwell_normal` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
 AND v.`Quality` = b.`Quality`
WHERE v.`description` LIKE '@Heroic Raid@%';

-- ---------------------------------------------------------------------------
-- 2) Resolve TBC Mythic dungeon bracket variants.
--    Restriction to the AtlasLoot TBC dungeon base-name list prevents Classic
--    or Wrath Mythic items with the same @Mythic N@ tags from leaking in.
-- ---------------------------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_dungeon_11_20`;
CREATE TEMPORARY TABLE `tmp_ms_dungeon_11_20`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_dungeon_11_20` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_tbc_dungeon_base` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
WHERE v.`RequiredLevel` = 70
  AND v.`Quality` >= 4
  AND v.`class` IN (2,4)
  AND v.`InventoryType` <> 0
  AND (
        v.`description` LIKE '@Mythic 11@%'
        OR v.`description` LIKE '@Mythic 12@%'
        OR v.`description` LIKE '@Mythic 13@%'
        OR v.`description` LIKE '@Mythic 14@%'
        OR v.`description` LIKE '@Mythic 15@%'
        OR v.`description` LIKE '@Mythic 16@%'
        OR v.`description` LIKE '@Mythic 17@%'
        OR v.`description` LIKE '@Mythic 18@%'
        OR v.`description` LIKE '@Mythic 19@%'
        OR v.`description` LIKE '@Mythic 20@%'
      );

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_dungeon_21_30`;
CREATE TEMPORARY TABLE `tmp_ms_dungeon_21_30`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_dungeon_21_30` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_tbc_dungeon_base` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
WHERE v.`RequiredLevel` = 70
  AND v.`Quality` >= 4
  AND v.`class` IN (2,4)
  AND v.`InventoryType` <> 0
  AND (
        v.`description` LIKE '@Mythic 21@%'
        OR v.`description` LIKE '@Mythic 22@%'
        OR v.`description` LIKE '@Mythic 23@%'
        OR v.`description` LIKE '@Mythic 24@%'
        OR v.`description` LIKE '@Mythic 25@%'
        OR v.`description` LIKE '@Mythic 26@%'
        OR v.`description` LIKE '@Mythic 27@%'
        OR v.`description` LIKE '@Mythic 28@%'
        OR v.`description` LIKE '@Mythic 29@%'
        OR v.`description` LIKE '@Mythic 30@%'
      );

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_dungeon_31_40`;
CREATE TEMPORARY TABLE `tmp_ms_dungeon_31_40`
(
    `item` INT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO `tmp_ms_dungeon_31_40` (`item`)
SELECT DISTINCT v.`entry`
FROM `tmp_ms_tbc_dungeon_base` s
JOIN `item_template` b ON b.`entry` = s.`item`
JOIN `item_template` v
  ON v.`name` = b.`name`
 AND v.`class` = b.`class`
 AND v.`subclass` = b.`subclass`
 AND v.`InventoryType` = b.`InventoryType`
WHERE v.`RequiredLevel` = 70
  AND v.`Quality` >= 4
  AND v.`class` IN (2,4)
  AND v.`InventoryType` <> 0
  AND (
        v.`description` LIKE '@Mythic 31@%'
        OR v.`description` LIKE '@Mythic 32@%'
        OR v.`description` LIKE '@Mythic 33@%'
        OR v.`description` LIKE '@Mythic 34@%'
        OR v.`description` LIKE '@Mythic 35@%'
        OR v.`description` LIKE '@Mythic 36@%'
        OR v.`description` LIKE '@Mythic 37@%'
        OR v.`description` LIKE '@Mythic 38@%'
        OR v.`description` LIKE '@Mythic 39@%'
        OR v.`description` LIKE '@Mythic 40@%'
      );

-- ---------------------------------------------------------------------------
-- 3) Pool sanity BEFORE replacing any cache loot.
--
-- Expected:
--   Hyjal Normal/Heroic/Mythic   79 / 79 / 79
--   BT Normal/Heroic/Mythic     102 / 102 / 102
--   Sunwell Heroic              108
--   Mythic Dungeon 11-20       2280
--   Mythic Dungeon 21-30       2280
--   Mythic Dungeon 31-40       2280
-- ---------------------------------------------------------------------------

SELECT 'Hyjal Normal' AS `pool`, COUNT(*) AS `rows` FROM `tmp_ms_hyjal_normal`
UNION ALL SELECT 'Hyjal Heroic', COUNT(*) FROM `tmp_ms_hyjal_heroic`
UNION ALL SELECT 'Hyjal Mythic', COUNT(*) FROM `tmp_ms_hyjal_mythic`
UNION ALL SELECT 'Black Temple Normal', COUNT(*) FROM `tmp_ms_bt_normal`
UNION ALL SELECT 'Black Temple Heroic', COUNT(*) FROM `tmp_ms_bt_heroic`
UNION ALL SELECT 'Black Temple Mythic', COUNT(*) FROM `tmp_ms_bt_mythic`
UNION ALL SELECT 'Sunwell Heroic', COUNT(*) FROM `tmp_ms_sunwell_heroic`
UNION ALL SELECT 'TBC Mythic Dungeon 11-20', COUNT(*) FROM `tmp_ms_dungeon_11_20`
UNION ALL SELECT 'TBC Mythic Dungeon 21-30', COUNT(*) FROM `tmp_ms_dungeon_21_30`
UNION ALL SELECT 'TBC Mythic Dungeon 31-40', COUNT(*) FROM `tmp_ms_dungeon_31_40`;

-- ---------------------------------------------------------------------------
-- 4) Build reusable personalized gear reference pools.
--
-- Every leaf pool is GroupId=1 / Chance=0. AzerothCore therefore exposes the
-- equal-chance candidate list to mod-manastorm-endless, which selects one item
-- using the opener's current primary-stat profile.
-- ---------------------------------------------------------------------------

DELETE FROM `reference_loot_template`
WHERE `Entry` IN
(
    9001001,
    9001002,
    9001003,
    9001010,
    9001011,
    9001012,
    9001021,
    9001031,
    9001032,
    9001033,
    9001041,
    9001042
);

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001001, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Normal Hyjal'
FROM `tmp_ms_hyjal_normal` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001002, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Heroic Hyjal'
FROM `tmp_ms_hyjal_heroic` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001003, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Mythic Hyjal'
FROM `tmp_ms_hyjal_mythic` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001010, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Normal Black Temple'
FROM `tmp_ms_bt_normal` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001011, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Heroic Black Temple'
FROM `tmp_ms_bt_heroic` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001012, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Mythic Black Temple'
FROM `tmp_ms_bt_mythic` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001021, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - Heroic Sunwell'
FROM `tmp_ms_sunwell_heroic` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001031, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - TBC Mythic Dungeon 11-20'
FROM `tmp_ms_dungeon_11_20` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001032, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - TBC Mythic Dungeon 21-30'
FROM `tmp_ms_dungeon_21_30` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001033, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS pool - TBC Mythic Dungeon 31-40'
FROM `tmp_ms_dungeon_31_40` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001041, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS fallback - Normal Hyjal'
FROM `tmp_ms_hyjal_normal` p
UNION ALL
SELECT 9001041, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS fallback - Normal Black Temple'
FROM `tmp_ms_bt_normal` p;

INSERT INTO `reference_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
SELECT 9001042, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS fallback - Heroic Hyjal'
FROM `tmp_ms_hyjal_heroic` p
UNION ALL
SELECT 9001042, p.`item`, 0, 0, 0, 1, 1, 1, 1, 'MS fallback - Heroic Black Temple'
FROM `tmp_ms_bt_heroic` p;

-- ---------------------------------------------------------------------------
-- 5) Replace the physical Black Temple cache policies.
--
-- Reference rows still participate in item_loot_template's (Entry, Item)
-- primary key. Item is therefore a unique non-dropping placeholder key within
-- each physical cache (1,2,3,...); Reference points at the real gear pool.
-- ---------------------------------------------------------------------------

DELETE FROM `item_loot_template`
WHERE `Entry` IN (1288068, 1288071, 1289071);

INSERT INTO `item_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
VALUES
(1288068, 1, 9001002, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS BT - Chance: Heroic Hyjal'),
(1288068, 2, 9001010, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS BT - Chance: Normal Black Temple'),
(1288068, 3, 9001031, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS BT - Chance: Mythic Dungeon 11-20'),
(1288068, 4, 9001001, 0,                       0, 1, 1, 1, 1, 'MS BT - Contains: Normal Hyjal');

INSERT INTO `item_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
VALUES
(1288071, 1, 9001002, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Heroic BT - Chance: Heroic Hyjal'),
(1288071, 2, 9001011, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Heroic BT - Chance: Heroic Black Temple'),
(1288071, 3, 9001032, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Heroic BT - Chance: Mythic Dungeon 21-30'),
(1288071, 4, 9001041, 0,                       0, 1, 1, 1, 1, 'MS Heroic BT - Contains: Normal BT or Hyjal');

INSERT INTO `item_loot_template`
(`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`)
VALUES
(1289071, 1, 9001021, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Mythic BT - Chance: Heroic Sunwell'),
(1289071, 2, 9001003, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Mythic BT - Chance: Mythic Hyjal'),
(1289071, 3, 9001012, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Mythic BT - Chance: Mythic Black Temple'),
(1289071, 4, 9001033, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 1, 1, 1, 'MS Mythic BT - Chance: Mythic Dungeon 31-40'),
(1289071, 5, 9001042, 0,                       0, 1, 1, 1, 1, 'MS Mythic BT - Contains: Heroic BT or Hyjal');

-- ---------------------------------------------------------------------------
-- 6) Verification.
-- ---------------------------------------------------------------------------

SELECT
    `Entry`,
    COUNT(*) AS `physical_policy_rows`,
    ROUND(SUM(CASE WHEN `Chance` > 0 THEN `Chance` ELSE 0 END), 6)
        AS `optional_family_total_pct`,
    SUM(CASE WHEN `Chance` = 0 THEN 1 ELSE 0 END)
        AS `fallback_references`
FROM `item_loot_template`
WHERE `Entry` IN (1288068,1288071,1289071)
GROUP BY `Entry`
ORDER BY `Entry`;

SELECT
    `Entry`,
    COUNT(*) AS `pool_rows`
FROM `reference_loot_template`
WHERE `Entry` BETWEEN 9001001 AND 9001042
GROUP BY `Entry`
ORDER BY `Entry`;

-- Expected physical policy rows:
--   1288068 = 4
--   1288071 = 4
--   1289071 = 5
--
-- Expected reference pool rows:
--   9001001 =   79
--   9001002 =   79
--   9001003 =   79
--   9001010 =  102
--   9001011 =  102
--   9001012 =  102
--   9001021 =  108
--   9001031 = 2280
--   9001032 = 2280
--   9001033 = 2280
--   9001041 =  181
--   9001042 =  181

-- ---------------------------------------------------------------------------
-- 7) Cleanup temporary tables.
-- ---------------------------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_hyjal_normal`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_bt_normal`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_sunwell_normal`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_tbc_dungeon_base`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_hyjal_heroic`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_hyjal_mythic`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_bt_heroic`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_bt_mythic`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_sunwell_heroic`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_dungeon_11_20`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_dungeon_21_30`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_dungeon_31_40`;
