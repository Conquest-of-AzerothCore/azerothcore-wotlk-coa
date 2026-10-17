-- Conquest of AzerothCore / mod-manastorm-endless
-- Classic Molten Core cache reconstruction, 2026-10-03.
-- Sources: recovered item_template(1).sql (Ascension 8.4.9, 2026-09-25);
-- Szyler/AtlasLootAscension Classic Instances.lua blob
-- dd69a91b91e79c7056c78669ee1e2b8e7471d407 and ClassicInstances.lua menu;
-- https://project-ascension.fandom.com/wiki/Mythic%2B_Guide reward catalog.
-- MC refs: 12118,11982,12259,12057,12264,12056,11988,12098,1750004,11502,11667.
-- Onyxia refs: 10184/10185 (Basalthane 10185 has no item rows in this source).
-- ZG refs: 14517,14507,14510,11382,15114,14509,14515,11380,14834,11350.
--
-- Base raid candidates are ordinary epic weapon/armor equipment, RequiredLevel
-- <=60, from those encounter/trash tables. Custom gear (including 12910 Molten
-- Slugtosser) is retained. Tokens, recipes, mounts, materials, special rewards,
-- and legendary components are excluded; non-equipment rows never enter leaves.
-- The 611-name historical dungeon reward catalog, including explicitly listed
-- UBRS rewards, is authoritative for dungeon candidates. This is NOT a union of
-- all modern Mythic-capable dungeons. Haunting Specter -> Spectre is a spelling
-- normalization. Duplicate ordinary Ironweave Robe rows resolve to one variant;
-- use base 22301. No inferred modern dungeon membership is added.
--
-- Variant matching uses name/class/subclass/InventoryType/Quality and PREFIX
-- difficulty descriptions. Classic raid-specific markers take precedence over
-- generic Raid markers: e.g. Deep Earth Spaulders has distinct Ascended Raid and
-- Ascended Molten Core rows. Multiple equally preferred candidates are excluded
-- and reported rather than arbitrarily picking an ID or substituting a tier.
-- Known omissions: 20 Heroic MC trash epics without matching variants;
-- Ascended Stockade Pauldrons has conflicting IDs 214552 and 314552.
-- Mythic 3 Tome of the Lost has conflicting IDs 8263152 and 8263154; exclude
-- that rank alone, preserving the other nine unambiguous dungeon ranks.
-- Dungeon variants can promote blue base gear to epic; level 60 is required.
--
-- Exact recovered descriptions (line breaks preserved for audit):
-- 1278056 Manastorm Cache: Molten Core
-- Obtained from Manastorm Levels: 221 to 280
-- Contains:
-- + Mythic Zul'Gurub Gear
-- + Normal Molten Core Gear
-- Chance to contain:
-- + Mythic Dungeon Gear
-- 1278058 Manastorm Cache: Heroic Molten Core
-- Obtained from Manastorm Levels: 281 to 340
-- Contains:
-- + Normal Molten Core Gear
-- Chance to contain:
-- + Heroic Molten Core Gear
-- + Mythic Dungeon Gear
-- 1278060 Manastorm Cache: Mythic Molten Core
-- Obtained from Manastorm Levels: 341 to 425
-- Contains:
-- + Heroic Molten Core Gear (1-2)
-- Chance to contain:
-- + Mythic Molten Core Gear
-- + Normal Onyxia Gear
-- + Mythic 1-10 Dungeon Gear
-- 1278061 Manastorm Cache: Onyxia & Molten Core
-- Manastorm 601 to 700\nContains gear up to Normal Onyxia's Lair!
-- 1278062 Manastorm Cache: Ascended Molten Core
-- @651 - 700@
-- 1278063 Manastorm Cache: Heroic Onyxia & Molten Core
-- Manastorm 701 to 750\nContains gear up to Heroic Onyxia's Lair!
-- 1278065 Manastorm Cache: Mythic Onyxia & Molten Core
-- Manastorm 801 to 900\nContains gear up to Mythic Onyxia's Lair!
-- 1278067 Manastorm Cache: Ascended Onyxia & Molten Core
-- @951 - 1000@
--
-- The direct trio implements every Contains family independently and every
-- Chance to contain family as an additional independent roll (GroupId=0).
-- (1-2) = one guaranteed Heroic MC roll plus a separate optional second roll.
-- AzerothCore reference MaxCount repeats a fixed number, not a random range;
-- MinCount=MaxCount=1 for every physical row. No invalid Chance=0/GroupId=0.
-- Pure gear leaves: Reference=0, Chance=0, GroupId=1. The existing equal-chance
-- hook personalizes one candidate per successful reference roll.
--
-- RECONSTRUCTION, NOT RECOVERED ORIGINAL ODDS:
-- optional families default to 10%; the second Heroic MC roll defaults to 50%.
-- Chances assume default server reference-drop rates; the core can scale them.
-- Later "gear up to" descriptions and @depth@ placeholders do not disclose
-- item counts, lower-tier membership, or chances. Conservative CoA policy:
-- one same-tier MC+Onyxia union roll for combined caches, one Ascended MC roll
-- for 1278062. These five profiles are inferred, not recovered additive lists.
-- No older/later depth snapshot is used to invent extra families or brackets.
--
-- All eight dump rows: Flags=2052 (HAS_LOOT), ScriptName='', spellid_1=18282.
-- Ordinary HAS_LOOT ownership is retained; no item_template write is required.
-- Ref namespace 9002xxx: absent from current module SQL and repository base
-- reference_loot_template. Runtime collision guards additionally reject any
-- reserved IDs already owned/referenced outside this migration.
-- Only these 8 cache entries and the 15 explicitly enumerated pools are changed.
-- Required dataset counts fail closed before persistent loot is touched.

SET @MS_OPTIONAL_FAMILY_PCT := 10.0;
SET @MS_SECOND_HEROIC_MC_PCT := 50.0;

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_source`;
CREATE TEMPORARY TABLE `tmp_ms_mc_source` (
    `Source` VARCHAR(32) NOT NULL,
    `Item` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`Source`, `Item`)
) ENGINE=InnoDB;

-- MoltenCore: 106 explicit base candidates.
INSERT INTO `tmp_ms_mc_source` (`Source`, `Item`) VALUES
('MoltenCore', 647),
('MoltenCore', 811),
('MoltenCore', 833),
('MoltenCore', 944),
('MoltenCore', 1168),
('MoltenCore', 1263),
('MoltenCore', 1443),
('MoltenCore', 1728),
('MoltenCore', 2099),
('MoltenCore', 2243),
('MoltenCore', 2244),
('MoltenCore', 2245),
('MoltenCore', 2246),
('MoltenCore', 2801),
('MoltenCore', 3475),
('MoltenCore', 10470),
('MoltenCore', 10529),
('MoltenCore', 10531),
('MoltenCore', 10532),
('MoltenCore', 10533),
('MoltenCore', 12572),
('MoltenCore', 12573),
('MoltenCore', 12594),
('MoltenCore', 12595),
('MoltenCore', 12597),
('MoltenCore', 12598),
('MoltenCore', 12599),
('MoltenCore', 12872),
('MoltenCore', 12908),
('MoltenCore', 12909),
('MoltenCore', 12910),
('MoltenCore', 12911),
('MoltenCore', 14552),
('MoltenCore', 14553),
('MoltenCore', 14554),
('MoltenCore', 14555),
('MoltenCore', 14557),
('MoltenCore', 14558),
('MoltenCore', 15712),
('MoltenCore', 15816),
('MoltenCore', 15956),
('MoltenCore', 15957),
('MoltenCore', 15958),
('MoltenCore', 15959),
('MoltenCore', 16010),
('MoltenCore', 16011),
('MoltenCore', 17063),
('MoltenCore', 17065),
('MoltenCore', 17066),
('MoltenCore', 17069),
('MoltenCore', 17071),
('MoltenCore', 17072),
('MoltenCore', 17073),
('MoltenCore', 17074),
('MoltenCore', 17076),
('MoltenCore', 17077),
('MoltenCore', 17082),
('MoltenCore', 17083),
('MoltenCore', 17102),
('MoltenCore', 17103),
('MoltenCore', 17104),
('MoltenCore', 17105),
('MoltenCore', 17106),
('MoltenCore', 17107),
('MoltenCore', 17109),
('MoltenCore', 17110),
('MoltenCore', 18203),
('MoltenCore', 18608),
('MoltenCore', 18609),
('MoltenCore', 18803),
('MoltenCore', 18805),
('MoltenCore', 18806),
('MoltenCore', 18808),
('MoltenCore', 18809),
('MoltenCore', 18810),
('MoltenCore', 18811),
('MoltenCore', 18812),
('MoltenCore', 18814),
('MoltenCore', 18815),
('MoltenCore', 18816),
('MoltenCore', 18817),
('MoltenCore', 18820),
('MoltenCore', 18821),
('MoltenCore', 18822),
('MoltenCore', 18823),
('MoltenCore', 18824),
('MoltenCore', 18829),
('MoltenCore', 18832),
('MoltenCore', 18842),
('MoltenCore', 18861),
('MoltenCore', 18870),
('MoltenCore', 18872),
('MoltenCore', 18875),
('MoltenCore', 18878),
('MoltenCore', 18879),
('MoltenCore', 19136),
('MoltenCore', 19137),
('MoltenCore', 19138),
('MoltenCore', 19139),
('MoltenCore', 19140),
('MoltenCore', 19142),
('MoltenCore', 19143),
('MoltenCore', 19144),
('MoltenCore', 19145),
('MoltenCore', 19146),
('MoltenCore', 19147);

-- Onyxia60: 14 explicit base candidates.
INSERT INTO `tmp_ms_mc_source` (`Source`, `Item`) VALUES
('Onyxia60', 11571),
('Onyxia60', 12596),
('Onyxia60', 17064),
('Onyxia60', 17067),
('Onyxia60', 17068),
('Onyxia60', 17075),
('Onyxia60', 17078),
('Onyxia60', 17084),
('Onyxia60', 18205),
('Onyxia60', 18211),
('Onyxia60', 18212),
('Onyxia60', 18215),
('Onyxia60', 18216),
('Onyxia60', 18813);

-- ZulGurub: 122 explicit base candidates.
INSERT INTO `tmp_ms_mc_source` (`Source`, `Item`) VALUES
('ZulGurub', 1728),
('ZulGurub', 3475),
('ZulGurub', 12390),
('ZulGurub', 12391),
('ZulGurub', 12473),
('ZulGurub', 12503),
('ZulGurub', 19822),
('ZulGurub', 19823),
('ZulGurub', 19824),
('ZulGurub', 19825),
('ZulGurub', 19826),
('ZulGurub', 19827),
('ZulGurub', 19828),
('ZulGurub', 19829),
('ZulGurub', 19830),
('ZulGurub', 19831),
('ZulGurub', 19832),
('ZulGurub', 19833),
('ZulGurub', 19834),
('ZulGurub', 19835),
('ZulGurub', 19836),
('ZulGurub', 19838),
('ZulGurub', 19839),
('ZulGurub', 19840),
('ZulGurub', 19841),
('ZulGurub', 19842),
('ZulGurub', 19843),
('ZulGurub', 19845),
('ZulGurub', 19846),
('ZulGurub', 19848),
('ZulGurub', 19849),
('ZulGurub', 19852),
('ZulGurub', 19853),
('ZulGurub', 19854),
('ZulGurub', 19855),
('ZulGurub', 19856),
('ZulGurub', 19857),
('ZulGurub', 19859),
('ZulGurub', 19861),
('ZulGurub', 19862),
('ZulGurub', 19863),
('ZulGurub', 19864),
('ZulGurub', 19865),
('ZulGurub', 19866),
('ZulGurub', 19867),
('ZulGurub', 19869),
('ZulGurub', 19870),
('ZulGurub', 19871),
('ZulGurub', 19873),
('ZulGurub', 19874),
('ZulGurub', 19875),
('ZulGurub', 19876),
('ZulGurub', 19877),
('ZulGurub', 19878),
('ZulGurub', 19884),
('ZulGurub', 19885),
('ZulGurub', 19886),
('ZulGurub', 19887),
('ZulGurub', 19888),
('ZulGurub', 19889),
('ZulGurub', 19890),
('ZulGurub', 19891),
('ZulGurub', 19892),
('ZulGurub', 19893),
('ZulGurub', 19894),
('ZulGurub', 19895),
('ZulGurub', 19896),
('ZulGurub', 19897),
('ZulGurub', 19898),
('ZulGurub', 19899),
('ZulGurub', 19900),
('ZulGurub', 19901),
('ZulGurub', 19903),
('ZulGurub', 19904),
('ZulGurub', 19905),
('ZulGurub', 19906),
('ZulGurub', 19907),
('ZulGurub', 19908),
('ZulGurub', 19909),
('ZulGurub', 19910),
('ZulGurub', 19912),
('ZulGurub', 19913),
('ZulGurub', 19915),
('ZulGurub', 19918),
('ZulGurub', 19919),
('ZulGurub', 19920),
('ZulGurub', 19921),
('ZulGurub', 19922),
('ZulGurub', 19923),
('ZulGurub', 19925),
('ZulGurub', 19927),
('ZulGurub', 19928),
('ZulGurub', 19929),
('ZulGurub', 19930),
('ZulGurub', 19944),
('ZulGurub', 19945),
('ZulGurub', 19946),
('ZulGurub', 19947),
('ZulGurub', 20032),
('ZulGurub', 20033),
('ZulGurub', 20034),
('ZulGurub', 20038),
('ZulGurub', 20257),
('ZulGurub', 20258),
('ZulGurub', 20259),
('ZulGurub', 20260),
('ZulGurub', 20261),
('ZulGurub', 20262),
('ZulGurub', 20263),
('ZulGurub', 20264),
('ZulGurub', 20265),
('ZulGurub', 20266),
('ZulGurub', 22711),
('ZulGurub', 22712),
('ZulGurub', 22713),
('ZulGurub', 22714),
('ZulGurub', 22715),
('ZulGurub', 22716),
('ZulGurub', 22718),
('ZulGurub', 22720),
('ZulGurub', 22721),
('ZulGurub', 22722);

-- ClassicDungeonCatalog: 611 explicit base candidates.
INSERT INTO `tmp_ms_mc_source` (`Source`, `Item`) VALUES
('ClassicDungeonCatalog', 11920),
('ClassicDungeonCatalog', 11921),
('ClassicDungeonCatalog', 11925),
('ClassicDungeonCatalog', 12582),
('ClassicDungeonCatalog', 12583),
('ClassicDungeonCatalog', 12590),
('ClassicDungeonCatalog', 12592),
('ClassicDungeonCatalog', 12603),
('ClassicDungeonCatalog', 12621),
('ClassicDungeonCatalog', 12634),
('ClassicDungeonCatalog', 12651),
('ClassicDungeonCatalog', 12709),
('ClassicDungeonCatalog', 12939),
('ClassicDungeonCatalog', 12940),
('ClassicDungeonCatalog', 12963),
('ClassicDungeonCatalog', 12964),
('ClassicDungeonCatalog', 12966),
('ClassicDungeonCatalog', 13183),
('ClassicDungeonCatalog', 13211),
('ClassicDungeonCatalog', 13218),
('ClassicDungeonCatalog', 13252),
('ClassicDungeonCatalog', 13257),
('ClassicDungeonCatalog', 13284),
('ClassicDungeonCatalog', 13285),
('ClassicDungeonCatalog', 13286),
('ClassicDungeonCatalog', 11626),
('ClassicDungeonCatalog', 11627),
('ClassicDungeonCatalog', 11628),
('ClassicDungeonCatalog', 11635),
('ClassicDungeonCatalog', 11679),
('ClassicDungeonCatalog', 11684),
('ClassicDungeonCatalog', 11685),
('ClassicDungeonCatalog', 11702),
('ClassicDungeonCatalog', 11726),
('ClassicDungeonCatalog', 11728),
('ClassicDungeonCatalog', 11729),
('ClassicDungeonCatalog', 11730),
('ClassicDungeonCatalog', 11731),
('ClassicDungeonCatalog', 11735),
('ClassicDungeonCatalog', 11749),
('ClassicDungeonCatalog', 11803),
('ClassicDungeonCatalog', 11814),
('ClassicDungeonCatalog', 11815),
('ClassicDungeonCatalog', 11817),
('ClassicDungeonCatalog', 11820),
('ClassicDungeonCatalog', 11821),
('ClassicDungeonCatalog', 11931),
('ClassicDungeonCatalog', 16666),
('ClassicDungeonCatalog', 16669),
('ClassicDungeonCatalog', 16670),
('ClassicDungeonCatalog', 16672),
('ClassicDungeonCatalog', 16673),
('ClassicDungeonCatalog', 16674),
('ClassicDungeonCatalog', 16676),
('ClassicDungeonCatalog', 16679),
('ClassicDungeonCatalog', 16680),
('ClassicDungeonCatalog', 16681),
('ClassicDungeonCatalog', 16710),
('ClassicDungeonCatalog', 16712),
('ClassicDungeonCatalog', 16713),
('ClassicDungeonCatalog', 16721),
('ClassicDungeonCatalog', 12528),
('ClassicDungeonCatalog', 12531),
('ClassicDungeonCatalog', 18047),
('ClassicDungeonCatalog', 13182),
('ClassicDungeonCatalog', 13340),
('ClassicDungeonCatalog', 13348),
('ClassicDungeonCatalog', 13358),
('ClassicDungeonCatalog', 13361),
('ClassicDungeonCatalog', 13368),
('ClassicDungeonCatalog', 13378),
('ClassicDungeonCatalog', 13401),
('ClassicDungeonCatalog', 13402),
('ClassicDungeonCatalog', 13408),
('ClassicDungeonCatalog', 13505),
('ClassicDungeonCatalog', 13952),
('ClassicDungeonCatalog', 13953),
('ClassicDungeonCatalog', 13967),
('ClassicDungeonCatalog', 13983),
('ClassicDungeonCatalog', 14024),
('ClassicDungeonCatalog', 22232),
('ClassicDungeonCatalog', 22269),
('ClassicDungeonCatalog', 14502),
('ClassicDungeonCatalog', 14503),
('ClassicDungeonCatalog', 14531),
('ClassicDungeonCatalog', 14539),
('ClassicDungeonCatalog', 14541),
('ClassicDungeonCatalog', 14637),
('ClassicDungeonCatalog', 28972),
('ClassicDungeonCatalog', 16667),
('ClassicDungeonCatalog', 16668),
('ClassicDungeonCatalog', 16671),
('ClassicDungeonCatalog', 16675),
('ClassicDungeonCatalog', 16677),
('ClassicDungeonCatalog', 16678),
('ClassicDungeonCatalog', 16707),
('ClassicDungeonCatalog', 16708),
('ClassicDungeonCatalog', 16709),
('ClassicDungeonCatalog', 16711),
('ClassicDungeonCatalog', 18043),
('ClassicDungeonCatalog', 18044),
('ClassicDungeonCatalog', 18296),
('ClassicDungeonCatalog', 18298),
('ClassicDungeonCatalog', 18302),
('ClassicDungeonCatalog', 18310),
('ClassicDungeonCatalog', 18324),
('ClassicDungeonCatalog', 18325),
('ClassicDungeonCatalog', 18344),
('ClassicDungeonCatalog', 18347),
('ClassicDungeonCatalog', 18349),
('ClassicDungeonCatalog', 18375),
('ClassicDungeonCatalog', 18379),
('ClassicDungeonCatalog', 18392),
('ClassicDungeonCatalog', 18393),
('ClassicDungeonCatalog', 18463),
('ClassicDungeonCatalog', 18484),
('ClassicDungeonCatalog', 18500),
('ClassicDungeonCatalog', 18520),
('ClassicDungeonCatalog', 18524),
('ClassicDungeonCatalog', 18530),
('ClassicDungeonCatalog', 18686),
('ClassicDungeonCatalog', 18698),
('ClassicDungeonCatalog', 18699),
('ClassicDungeonCatalog', 18718),
('ClassicDungeonCatalog', 18725),
('ClassicDungeonCatalog', 18736),
('ClassicDungeonCatalog', 18737),
('ClassicDungeonCatalog', 18742),
('ClassicDungeonCatalog', 18744),
('ClassicDungeonCatalog', 18758),
('ClassicDungeonCatalog', 18759),
('ClassicDungeonCatalog', 22204),
('ClassicDungeonCatalog', 22207),
('ClassicDungeonCatalog', 22208),
('ClassicDungeonCatalog', 22212),
('ClassicDungeonCatalog', 22241),
('ClassicDungeonCatalog', 22242),
('ClassicDungeonCatalog', 22255),
('ClassicDungeonCatalog', 22270),
('ClassicDungeonCatalog', 22314),
('ClassicDungeonCatalog', 22317),
('ClassicDungeonCatalog', 22322),
('ClassicDungeonCatalog', 22325),
('ClassicDungeonCatalog', 22332),
('ClassicDungeonCatalog', 22343),
('ClassicDungeonCatalog', 22397),
('ClassicDungeonCatalog', 22410),
('ClassicDungeonCatalog', 22472),
('ClassicDungeonCatalog', 11922),
('ClassicDungeonCatalog', 12589),
('ClassicDungeonCatalog', 12604),
('ClassicDungeonCatalog', 12605),
('ClassicDungeonCatalog', 12606),
('ClassicDungeonCatalog', 12626),
('ClassicDungeonCatalog', 12930),
('ClassicDungeonCatalog', 12965),
('ClassicDungeonCatalog', 12967),
('ClassicDungeonCatalog', 12968),
('ClassicDungeonCatalog', 13141),
('ClassicDungeonCatalog', 13161),
('ClassicDungeonCatalog', 13168),
('ClassicDungeonCatalog', 13169),
('ClassicDungeonCatalog', 13170),
('ClassicDungeonCatalog', 13179),
('ClassicDungeonCatalog', 13184),
('ClassicDungeonCatalog', 13185),
('ClassicDungeonCatalog', 13244),
('ClassicDungeonCatalog', 13253),
('ClassicDungeonCatalog', 13261),
('ClassicDungeonCatalog', 13282),
('ClassicDungeonCatalog', 11623),
('ClassicDungeonCatalog', 11625),
('ClassicDungeonCatalog', 11634),
('ClassicDungeonCatalog', 11662),
('ClassicDungeonCatalog', 11665),
('ClassicDungeonCatalog', 11722),
('ClassicDungeonCatalog', 11748),
('ClassicDungeonCatalog', 11768),
('ClassicDungeonCatalog', 11782),
('ClassicDungeonCatalog', 11784),
('ClassicDungeonCatalog', 11807),
('ClassicDungeonCatalog', 11819),
('ClassicDungeonCatalog', 11822),
('ClassicDungeonCatalog', 11823),
('ClassicDungeonCatalog', 11824),
('ClassicDungeonCatalog', 11832),
('ClassicDungeonCatalog', 11839),
('ClassicDungeonCatalog', 11924),
('ClassicDungeonCatalog', 11932),
('ClassicDungeonCatalog', 16683),
('ClassicDungeonCatalog', 16685),
('ClassicDungeonCatalog', 16688),
('ClassicDungeonCatalog', 16695),
('ClassicDungeonCatalog', 16700),
('ClassicDungeonCatalog', 16703),
('ClassicDungeonCatalog', 16706),
('ClassicDungeonCatalog', 16718),
('ClassicDungeonCatalog', 12103),
('ClassicDungeonCatalog', 12532),
('ClassicDungeonCatalog', 12542),
('ClassicDungeonCatalog', 12546),
('ClassicDungeonCatalog', 12547),
('ClassicDungeonCatalog', 12549),
('ClassicDungeonCatalog', 18102),
('ClassicDungeonCatalog', 18104),
('ClassicDungeonCatalog', 13181),
('ClassicDungeonCatalog', 13314),
('ClassicDungeonCatalog', 13344),
('ClassicDungeonCatalog', 13345),
('ClassicDungeonCatalog', 13349),
('ClassicDungeonCatalog', 13353),
('ClassicDungeonCatalog', 13371),
('ClassicDungeonCatalog', 13376),
('ClassicDungeonCatalog', 13385),
('ClassicDungeonCatalog', 13396),
('ClassicDungeonCatalog', 13398),
('ClassicDungeonCatalog', 13403),
('ClassicDungeonCatalog', 13938),
('ClassicDungeonCatalog', 13969),
('ClassicDungeonCatalog', 22231),
('ClassicDungeonCatalog', 22247),
('ClassicDungeonCatalog', 22253),
('ClassicDungeonCatalog', 22267),
('ClassicDungeonCatalog', 23198),
('ClassicDungeonCatalog', 14487),
('ClassicDungeonCatalog', 14522),
('ClassicDungeonCatalog', 14538),
('ClassicDungeonCatalog', 14545),
('ClassicDungeonCatalog', 14577),
('ClassicDungeonCatalog', 16682),
('ClassicDungeonCatalog', 16684),
('ClassicDungeonCatalog', 16686),
('ClassicDungeonCatalog', 16689),
('ClassicDungeonCatalog', 16698),
('ClassicDungeonCatalog', 16699),
('ClassicDungeonCatalog', 16701),
('ClassicDungeonCatalog', 16702),
('ClassicDungeonCatalog', 16704),
('ClassicDungeonCatalog', 16705),
('ClassicDungeonCatalog', 16714),
('ClassicDungeonCatalog', 18289),
('ClassicDungeonCatalog', 18301),
('ClassicDungeonCatalog', 18307),
('ClassicDungeonCatalog', 18308),
('ClassicDungeonCatalog', 18309),
('ClassicDungeonCatalog', 18311),
('ClassicDungeonCatalog', 18317),
('ClassicDungeonCatalog', 18318),
('ClassicDungeonCatalog', 18321),
('ClassicDungeonCatalog', 18322),
('ClassicDungeonCatalog', 18327),
('ClassicDungeonCatalog', 18338),
('ClassicDungeonCatalog', 18345),
('ClassicDungeonCatalog', 18353),
('ClassicDungeonCatalog', 18372),
('ClassicDungeonCatalog', 18373),
('ClassicDungeonCatalog', 18378),
('ClassicDungeonCatalog', 18385),
('ClassicDungeonCatalog', 18386),
('ClassicDungeonCatalog', 18387),
('ClassicDungeonCatalog', 18389),
('ClassicDungeonCatalog', 18390),
('ClassicDungeonCatalog', 18391),
('ClassicDungeonCatalog', 18395),
('ClassicDungeonCatalog', 18396),
('ClassicDungeonCatalog', 18450),
('ClassicDungeonCatalog', 18458),
('ClassicDungeonCatalog', 18459),
('ClassicDungeonCatalog', 18477),
('ClassicDungeonCatalog', 18490),
('ClassicDungeonCatalog', 18494),
('ClassicDungeonCatalog', 18496),
('ClassicDungeonCatalog', 18507),
('ClassicDungeonCatalog', 18525),
('ClassicDungeonCatalog', 18526),
('ClassicDungeonCatalog', 18527),
('ClassicDungeonCatalog', 18528),
('ClassicDungeonCatalog', 18532),
('ClassicDungeonCatalog', 18534),
('ClassicDungeonCatalog', 18681),
('ClassicDungeonCatalog', 18682),
('ClassicDungeonCatalog', 18691),
('ClassicDungeonCatalog', 18693),
('ClassicDungeonCatalog', 18695),
('ClassicDungeonCatalog', 18697),
('ClassicDungeonCatalog', 18717),
('ClassicDungeonCatalog', 18720),
('ClassicDungeonCatalog', 18721),
('ClassicDungeonCatalog', 18727),
('ClassicDungeonCatalog', 18730),
('ClassicDungeonCatalog', 18735),
('ClassicDungeonCatalog', 18739),
('ClassicDungeonCatalog', 18740),
('ClassicDungeonCatalog', 18741),
('ClassicDungeonCatalog', 18743),
('ClassicDungeonCatalog', 18745),
('ClassicDungeonCatalog', 18761),
('ClassicDungeonCatalog', 22234),
('ClassicDungeonCatalog', 22240),
('ClassicDungeonCatalog', 22254),
('ClassicDungeonCatalog', 22256),
('ClassicDungeonCatalog', 22257),
('ClassicDungeonCatalog', 22271),
('ClassicDungeonCatalog', 22275),
('ClassicDungeonCatalog', 22315),
('ClassicDungeonCatalog', 22319),
('ClassicDungeonCatalog', 22330),
('ClassicDungeonCatalog', 22333),
('ClassicDungeonCatalog', 22335),
('ClassicDungeonCatalog', 22342),
('ClassicDungeonCatalog', 22395),
('ClassicDungeonCatalog', 22403),
('ClassicDungeonCatalog', 22406),
('ClassicDungeonCatalog', 22407),
('ClassicDungeonCatalog', 22409),
('ClassicDungeonCatalog', 22412),
('ClassicDungeonCatalog', 12608),
('ClassicDungeonCatalog', 12609),
('ClassicDungeonCatalog', 12653),
('ClassicDungeonCatalog', 12927),
('ClassicDungeonCatalog', 12936),
('ClassicDungeonCatalog', 13098),
('ClassicDungeonCatalog', 13143),
('ClassicDungeonCatalog', 13166),
('ClassicDungeonCatalog', 13198),
('ClassicDungeonCatalog', 13203),
('ClassicDungeonCatalog', 13210),
('ClassicDungeonCatalog', 13212),
('ClassicDungeonCatalog', 13213),
('ClassicDungeonCatalog', 13255),
('ClassicDungeonCatalog', 13283),
('ClassicDungeonCatalog', 11677),
('ClassicDungeonCatalog', 11744),
('ClassicDungeonCatalog', 11808),
('ClassicDungeonCatalog', 11809),
('ClassicDungeonCatalog', 11812),
('ClassicDungeonCatalog', 11933),
('ClassicDungeonCatalog', 12551),
('ClassicDungeonCatalog', 18103),
('ClassicDungeonCatalog', 13148),
('ClassicDungeonCatalog', 13164),
('ClassicDungeonCatalog', 13359),
('ClassicDungeonCatalog', 13374),
('ClassicDungeonCatalog', 13379),
('ClassicDungeonCatalog', 13382),
('ClassicDungeonCatalog', 13395),
('ClassicDungeonCatalog', 13399),
('ClassicDungeonCatalog', 13404),
('ClassicDungeonCatalog', 13515),
('ClassicDungeonCatalog', 13529),
('ClassicDungeonCatalog', 13954),
('ClassicDungeonCatalog', 13956),
('ClassicDungeonCatalog', 22321),
('ClassicDungeonCatalog', 14340),
('ClassicDungeonCatalog', 14636),
('ClassicDungeonCatalog', 14638),
('ClassicDungeonCatalog', 14640),
('ClassicDungeonCatalog', 14641),
('ClassicDungeonCatalog', 17061),
('ClassicDungeonCatalog', 18306),
('ClassicDungeonCatalog', 18314),
('ClassicDungeonCatalog', 18328),
('ClassicDungeonCatalog', 18346),
('ClassicDungeonCatalog', 18350),
('ClassicDungeonCatalog', 18354),
('ClassicDungeonCatalog', 18371),
('ClassicDungeonCatalog', 18388),
('ClassicDungeonCatalog', 18397),
('ClassicDungeonCatalog', 18451),
('ClassicDungeonCatalog', 18475),
('ClassicDungeonCatalog', 18479),
('ClassicDungeonCatalog', 18505),
('ClassicDungeonCatalog', 18523),
('ClassicDungeonCatalog', 18680),
('ClassicDungeonCatalog', 18694),
('ClassicDungeonCatalog', 18726),
('ClassicDungeonCatalog', 18728),
('ClassicDungeonCatalog', 18729),
('ClassicDungeonCatalog', 18738),
('ClassicDungeonCatalog', 18755),
('ClassicDungeonCatalog', 22326),
('ClassicDungeonCatalog', 22339),
('ClassicDungeonCatalog', 22340),
('ClassicDungeonCatalog', 22345),
('ClassicDungeonCatalog', 22401),
('ClassicDungeonCatalog', 22404),
('ClassicDungeonCatalog', 22433),
('ClassicDungeonCatalog', 11923),
('ClassicDungeonCatalog', 11929),
('ClassicDungeonCatalog', 13178),
('ClassicDungeonCatalog', 13206),
('ClassicDungeonCatalog', 13208),
('ClassicDungeonCatalog', 11624),
('ClassicDungeonCatalog', 11747),
('ClassicDungeonCatalog', 11750),
('ClassicDungeonCatalog', 11783),
('ClassicDungeonCatalog', 11841),
('ClassicDungeonCatalog', 11842),
('ClassicDungeonCatalog', 11928),
('ClassicDungeonCatalog', 11935),
('ClassicDungeonCatalog', 16690),
('ClassicDungeonCatalog', 16696),
('ClassicDungeonCatalog', 16715),
('ClassicDungeonCatalog', 16716),
('ClassicDungeonCatalog', 16717),
('ClassicDungeonCatalog', 18048),
('ClassicDungeonCatalog', 13346),
('ClassicDungeonCatalog', 13360),
('ClassicDungeonCatalog', 13369),
('ClassicDungeonCatalog', 13383),
('ClassicDungeonCatalog', 13534),
('ClassicDungeonCatalog', 13937),
('ClassicDungeonCatalog', 13960),
('ClassicDungeonCatalog', 13964),
('ClassicDungeonCatalog', 22268),
('ClassicDungeonCatalog', 14548),
('ClassicDungeonCatalog', 14626),
('ClassicDungeonCatalog', 14633),
('ClassicDungeonCatalog', 16687),
('ClassicDungeonCatalog', 16691),
('ClassicDungeonCatalog', 16692),
('ClassicDungeonCatalog', 16693),
('ClassicDungeonCatalog', 16694),
('ClassicDungeonCatalog', 16697),
('ClassicDungeonCatalog', 16719),
('ClassicDungeonCatalog', 16720),
('ClassicDungeonCatalog', 18483),
('ClassicDungeonCatalog', 18497),
('ClassicDungeonCatalog', 18723),
('ClassicDungeonCatalog', 22245),
('ClassicDungeonCatalog', 22266),
('ClassicDungeonCatalog', 22394),
('ClassicDungeonCatalog', 22398),
('ClassicDungeonCatalog', 22405),
('ClassicDungeonCatalog', 22408),
('ClassicDungeonCatalog', 23200),
('ClassicDungeonCatalog', 23201),
('ClassicDungeonCatalog', 11926),
('ClassicDungeonCatalog', 12587),
('ClassicDungeonCatalog', 12637),
('ClassicDungeonCatalog', 12929),
('ClassicDungeonCatalog', 12935),
('ClassicDungeonCatalog', 12969),
('ClassicDungeonCatalog', 13142),
('ClassicDungeonCatalog', 13162),
('ClassicDungeonCatalog', 13167),
('ClassicDungeonCatalog', 13204),
('ClassicDungeonCatalog', 13498),
('ClassicDungeonCatalog', 11629),
('ClassicDungeonCatalog', 11632),
('ClassicDungeonCatalog', 11633),
('ClassicDungeonCatalog', 11686),
('ClassicDungeonCatalog', 11745),
('ClassicDungeonCatalog', 11802),
('ClassicDungeonCatalog', 11816),
('ClassicDungeonCatalog', 16726),
('ClassicDungeonCatalog', 16729),
('ClassicDungeonCatalog', 16730),
('ClassicDungeonCatalog', 16733),
('ClassicDungeonCatalog', 16735),
('ClassicDungeonCatalog', 16736),
('ClassicDungeonCatalog', 12535),
('ClassicDungeonCatalog', 12552),
('ClassicDungeonCatalog', 12791),
('ClassicDungeonCatalog', 12793),
('ClassicDungeonCatalog', 13372),
('ClassicDungeonCatalog', 13381),
('ClassicDungeonCatalog', 13384),
('ClassicDungeonCatalog', 13400),
('ClassicDungeonCatalog', 13944),
('ClassicDungeonCatalog', 13957),
('ClassicDungeonCatalog', 22311),
('ClassicDungeonCatalog', 22313),
('ClassicDungeonCatalog', 14612),
('ClassicDungeonCatalog', 14615),
('ClassicDungeonCatalog', 14616),
('ClassicDungeonCatalog', 16722),
('ClassicDungeonCatalog', 16723),
('ClassicDungeonCatalog', 16724),
('ClassicDungeonCatalog', 16725),
('ClassicDungeonCatalog', 16727),
('ClassicDungeonCatalog', 16728),
('ClassicDungeonCatalog', 16731),
('ClassicDungeonCatalog', 16732),
('ClassicDungeonCatalog', 16734),
('ClassicDungeonCatalog', 16737),
('ClassicDungeonCatalog', 18312),
('ClassicDungeonCatalog', 18323),
('ClassicDungeonCatalog', 18380),
('ClassicDungeonCatalog', 18460),
('ClassicDungeonCatalog', 18462),
('ClassicDungeonCatalog', 18464),
('ClassicDungeonCatalog', 18498),
('ClassicDungeonCatalog', 18522),
('ClassicDungeonCatalog', 18533),
('ClassicDungeonCatalog', 18683),
('ClassicDungeonCatalog', 18689),
('ClassicDungeonCatalog', 18722),
('ClassicDungeonCatalog', 18734),
('ClassicDungeonCatalog', 18760),
('ClassicDungeonCatalog', 22205),
('ClassicDungeonCatalog', 22302),
('ClassicDungeonCatalog', 22303),
('ClassicDungeonCatalog', 22304),
('ClassicDungeonCatalog', 22305),
('ClassicDungeonCatalog', 22306),
('ClassicDungeonCatalog', 22337),
('ClassicDungeonCatalog', 22411),
('ClassicDungeonCatalog', 11927),
('ClassicDungeonCatalog', 12602),
('ClassicDungeonCatalog', 12905),
('ClassicDungeonCatalog', 13163),
('ClassicDungeonCatalog', 13177),
('ClassicDungeonCatalog', 13205),
('ClassicDungeonCatalog', 13259),
('ClassicDungeonCatalog', 13502),
('ClassicDungeonCatalog', 11631),
('ClassicDungeonCatalog', 11669),
('ClassicDungeonCatalog', 11675),
('ClassicDungeonCatalog', 11678),
('ClassicDungeonCatalog', 11703),
('ClassicDungeonCatalog', 11746),
('ClassicDungeonCatalog', 11755),
('ClassicDungeonCatalog', 11785),
('ClassicDungeonCatalog', 11786),
('ClassicDungeonCatalog', 11787),
('ClassicDungeonCatalog', 11805),
('ClassicDungeonCatalog', 11810),
('ClassicDungeonCatalog', 11930),
('ClassicDungeonCatalog', 12550),
('ClassicDungeonCatalog', 12555),
('ClassicDungeonCatalog', 12588),
('ClassicDungeonCatalog', 13373),
('ClassicDungeonCatalog', 13375),
('ClassicDungeonCatalog', 13380),
('ClassicDungeonCatalog', 13386),
('ClassicDungeonCatalog', 13394),
('ClassicDungeonCatalog', 13397),
('ClassicDungeonCatalog', 13405),
('ClassicDungeonCatalog', 13951),
('ClassicDungeonCatalog', 13955),
('ClassicDungeonCatalog', 14525),
('ClassicDungeonCatalog', 14528),
('ClassicDungeonCatalog', 14537),
('ClassicDungeonCatalog', 14611),
('ClassicDungeonCatalog', 14614),
('ClassicDungeonCatalog', 14620),
('ClassicDungeonCatalog', 14621),
('ClassicDungeonCatalog', 14622),
('ClassicDungeonCatalog', 14623),
('ClassicDungeonCatalog', 14624),
('ClassicDungeonCatalog', 18305),
('ClassicDungeonCatalog', 18313),
('ClassicDungeonCatalog', 18315),
('ClassicDungeonCatalog', 18326),
('ClassicDungeonCatalog', 18340),
('ClassicDungeonCatalog', 18351),
('ClassicDungeonCatalog', 18352),
('ClassicDungeonCatalog', 18370),
('ClassicDungeonCatalog', 18374),
('ClassicDungeonCatalog', 18376),
('ClassicDungeonCatalog', 18377),
('ClassicDungeonCatalog', 18381),
('ClassicDungeonCatalog', 18383),
('ClassicDungeonCatalog', 18384),
('ClassicDungeonCatalog', 18394),
('ClassicDungeonCatalog', 18485),
('ClassicDungeonCatalog', 18493),
('ClassicDungeonCatalog', 18495),
('ClassicDungeonCatalog', 18499),
('ClassicDungeonCatalog', 18502),
('ClassicDungeonCatalog', 18503),
('ClassicDungeonCatalog', 18521),
('ClassicDungeonCatalog', 18531),
('ClassicDungeonCatalog', 18537),
('ClassicDungeonCatalog', 18690),
('ClassicDungeonCatalog', 18696),
('ClassicDungeonCatalog', 18700),
('ClassicDungeonCatalog', 18716),
('ClassicDungeonCatalog', 18754),
('ClassicDungeonCatalog', 18756),
('ClassicDungeonCatalog', 22223),
('ClassicDungeonCatalog', 22318),
('ClassicDungeonCatalog', 22331),
('ClassicDungeonCatalog', 22336),
('ClassicDungeonCatalog', 22400),
('ClassicDungeonCatalog', 12557),
('ClassicDungeonCatalog', 12553),
('ClassicDungeonCatalog', 12554),
('ClassicDungeonCatalog', 13524),
('ClassicDungeonCatalog', 18476),
('ClassicDungeonCatalog', 14543),
('ClassicDungeonCatalog', 18702),
('ClassicDungeonCatalog', 14536),
('ClassicDungeonCatalog', 14576),
('ClassicDungeonCatalog', 12556),
('ClassicDungeonCatalog', 18757),
('ClassicDungeonCatalog', 22329),
('ClassicDungeonCatalog', 22301),
('ClassicDungeonCatalog', 18538),
('ClassicDungeonCatalog', 18425),
('ClassicDungeonCatalog', 13950),
('ClassicDungeonCatalog', 22334),
('ClassicDungeonCatalog', 18481),
('ClassicDungeonCatalog', 18692),
('ClassicDungeonCatalog', 18480),
('ClassicDungeonCatalog', 22327),
('ClassicDungeonCatalog', 18478),
('ClassicDungeonCatalog', 22328),
('ClassicDungeonCatalog', 18701),
('ClassicDungeonCatalog', 18482);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_family`;
CREATE TEMPORARY TABLE `tmp_ms_mc_family` (
    `Entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `Label` VARCHAR(64) NOT NULL,
    `Source` VARCHAR(32) NOT NULL,
    `Tier` VARCHAR(16) NOT NULL,
    `SpecificMarker` VARCHAR(64) NOT NULL,
    `Expected` INT UNSIGNED NOT NULL
) ENGINE=InnoDB;
INSERT INTO `tmp_ms_mc_family` (`Entry`, `Label`, `Source`, `Tier`, `SpecificMarker`, `Expected`) VALUES
(9002001, 'Normal Molten Core', 'MoltenCore', '', '', 106),
(9002002, 'Heroic Molten Core', 'MoltenCore', 'Heroic', '@Heroic Molten Core@%', 86),
(9002003, 'Mythic Molten Core', 'MoltenCore', 'Mythic', '@Mythic Molten Core@%', 106),
(9002004, 'Ascended Molten Core', 'MoltenCore', 'Ascended', '@Ascended Molten Core@%', 105),
(9002010, 'Normal Onyxia', 'Onyxia60', '', '', 14),
(9002011, 'Heroic Onyxia', 'Onyxia60', 'Heroic', '@Heroic Onyxia@%', 14),
(9002012, 'Mythic Onyxia', 'Onyxia60', 'Mythic', '@Mythic Onyxia@%', 14),
(9002013, 'Ascended Onyxia', 'Onyxia60', 'Ascended', '@Ascended Onyxia@%', 14),
(9002022, 'Mythic Zul''Gurub', 'ZulGurub', 'Mythic', '@Mythic Zul''Gurub@%', 122),
(9002030, 'Classic Mythic Dungeon', 'ClassicDungeonCatalog', 'Dungeon', '', 611),
(9002031, 'Classic Mythic Dungeon 1-10', 'ClassicDungeonCatalog', 'Band', '', 6109),
(9002040, 'Normal MC + Onyxia', 'Combined', '', '', 120),
(9002041, 'Heroic MC + Onyxia', 'Combined', '', '', 100),
(9002042, 'Mythic MC + Onyxia', 'Combined', '', '', 120),
(9002043, 'Ascended MC + Onyxia', 'Combined', '', '', 119);

-- Scan the large recovered item table once and index a narrow temporary lookup.
-- Avoid repeated full item_template scans; never alter its persistent indexes.
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_variant`;
CREATE TEMPORARY TABLE `tmp_ms_mc_variant` ENGINE=InnoDB AS
SELECT `entry`, `name`, `class`, `subclass`, `InventoryType`, `Quality`, `RequiredLevel`, `description`
FROM `item_template`
WHERE `class` IN (2, 4) AND `InventoryType` <> 0 AND `Quality` = 4 AND `RequiredLevel` <= 60;
ALTER TABLE `tmp_ms_mc_variant` ADD PRIMARY KEY (`entry`),
    ADD INDEX `variant_name` (`name`, `class`, `subclass`, `InventoryType`);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_matches`;
CREATE TEMPORARY TABLE `tmp_ms_mc_matches` (
    `Entry` INT UNSIGNED NOT NULL,
    `BaseItem` INT UNSIGNED NOT NULL,
    `Item` INT UNSIGNED NOT NULL,
    `Priority` TINYINT UNSIGNED NOT NULL,
    `Band` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`Entry`, `BaseItem`, `Item`)
) ENGINE=InnoDB;
INSERT INTO `tmp_ms_mc_matches` (`Entry`, `BaseItem`, `Item`, `Priority`, `Band`)
SELECT `f`.`Entry`, `b`.`entry`, `v`.`entry`,
    IF(`f`.`SpecificMarker` <> '' AND `v`.`description` LIKE `f`.`SpecificMarker`, 0, 1),
    IF(`f`.`Tier` = 'Band', CAST(SUBSTRING_INDEX(SUBSTRING(`v`.`description`, 9), '@', 1) AS UNSIGNED), 0)
FROM `tmp_ms_mc_family` AS `f`
JOIN `tmp_ms_mc_source` AS `s` ON `s`.`Source` = `f`.`Source`
JOIN `item_template` AS `b` ON `b`.`entry` = `s`.`Item`
JOIN `tmp_ms_mc_variant` AS `v` ON `v`.`name` = `b`.`name`
    AND `v`.`class` = `b`.`class` AND `v`.`subclass` = `b`.`subclass`
    AND `v`.`InventoryType` = `b`.`InventoryType`
WHERE `b`.`class` IN (2, 4) AND `b`.`InventoryType` <> 0
    AND `b`.`RequiredLevel` <= 60 AND `v`.`Quality` = 4
    AND `v`.`RequiredLevel` <= 60
    AND (
        (`f`.`Tier` = '' AND `v`.`entry` = `b`.`entry` AND `b`.`Quality` = 4)
        OR (`f`.`Tier` IN ('Heroic', 'Mythic', 'Ascended') AND `v`.`Quality` = `b`.`Quality`
            AND (`v`.`description` LIKE `f`.`SpecificMarker`
                OR `v`.`description` LIKE CONCAT('@', `f`.`Tier`, ' Raid@%')))
        OR (`f`.`Tier` = 'Dungeon' AND `v`.`RequiredLevel` = 60
            AND (`v`.`description` LIKE '@Mythic Dungeon@%' OR `v`.`description` LIKE '@Mythic@%'))
        OR (`f`.`Tier` = 'Band' AND `v`.`RequiredLevel` = 60 AND (
            `v`.`description` LIKE '@Mythic 1@%' OR `v`.`description` LIKE '@Mythic 2@%'
            OR `v`.`description` LIKE '@Mythic 3@%' OR `v`.`description` LIKE '@Mythic 4@%'
            OR `v`.`description` LIKE '@Mythic 5@%' OR `v`.`description` LIKE '@Mythic 6@%'
            OR `v`.`description` LIKE '@Mythic 7@%' OR `v`.`description` LIKE '@Mythic 8@%'
            OR `v`.`description` LIKE '@Mythic 9@%' OR `v`.`description` LIKE '@Mythic 10@%'))
    );

-- Materialize preference and uniqueness separately: MySQL temporary tables
-- cannot be reopened twice in one query. Band uniqueness is checked per rank.
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_priority`;
CREATE TEMPORARY TABLE `tmp_ms_mc_priority` ENGINE=InnoDB AS
SELECT `Entry`, `BaseItem`, `Band`, MIN(`Priority`) AS `Priority`
FROM `tmp_ms_mc_matches` GROUP BY `Entry`, `BaseItem`, `Band`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_preferred`;
CREATE TEMPORARY TABLE `tmp_ms_mc_preferred` ENGINE=InnoDB AS
SELECT `m`.`Entry`, `m`.`BaseItem`, `m`.`Item`, `m`.`Band`
FROM `tmp_ms_mc_matches` AS `m`
JOIN `tmp_ms_mc_priority` AS `p` USING (`Entry`, `BaseItem`, `Band`, `Priority`);
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_unique`;
CREATE TEMPORARY TABLE `tmp_ms_mc_unique` ENGINE=InnoDB AS
SELECT `Entry`, `BaseItem`, `Band`, COUNT(*) AS `Candidates`
FROM `tmp_ms_mc_preferred` GROUP BY `Entry`, `BaseItem`, `Band`;
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_pool`;
CREATE TEMPORARY TABLE `tmp_ms_mc_pool` (
    `Entry` INT UNSIGNED NOT NULL,
    `Item` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`Entry`, `Item`)
) ENGINE=InnoDB;
INSERT INTO `tmp_ms_mc_pool` (`Entry`, `Item`)
SELECT DISTINCT `p`.`Entry`, `p`.`Item`
FROM `tmp_ms_mc_preferred` AS `p`
JOIN `tmp_ms_mc_unique` AS `u` USING (`Entry`, `BaseItem`, `Band`)
WHERE `u`.`Candidates` = 1;
-- Combined pools are leaf unions, not nested references (required by the hook).
DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_combined`;
CREATE TEMPORARY TABLE `tmp_ms_mc_combined` ENGINE=InnoDB AS
-- Read the temporary table once. DISTINCT preserves the old UNION deduplication.
SELECT DISTINCT CASE WHEN `Entry` BETWEEN 9002001 AND 9002004
    THEN 9002040 + (`Entry` - 9002001)
    ELSE 9002040 + (`Entry` - 9002010) END AS `Entry`, `Item`
FROM `tmp_ms_mc_pool`
WHERE `Entry` BETWEEN 9002001 AND 9002004 OR `Entry` BETWEEN 9002010 AND 9002013;
INSERT INTO `tmp_ms_mc_pool` (`Entry`, `Item`)
SELECT `Entry`, `Item` FROM `tmp_ms_mc_combined`;

-- Audit missing and ambiguous raid variants; no cross-tier substitutions.
SELECT `f`.`Label`, `b`.`entry` AS `BaseItem`, `b`.`name`,
    COALESCE(`u`.`Candidates`, 0) AS `Candidates`
FROM `tmp_ms_mc_family` AS `f`
JOIN `tmp_ms_mc_source` AS `s` ON `s`.`Source` = `f`.`Source`
JOIN `item_template` AS `b` ON `b`.`entry` = `s`.`Item`
LEFT JOIN `tmp_ms_mc_unique` AS `u` ON `u`.`Entry` = `f`.`Entry` AND `u`.`BaseItem` = `s`.`Item`
WHERE `f`.`Tier` IN ('Heroic', 'Mythic', 'Ascended')
    AND COALESCE(`u`.`Candidates`, 0) <> 1
ORDER BY `f`.`Entry`, `b`.`entry`;
SELECT `p`.`Entry`, `p`.`BaseItem`, `p`.`Item` AS `AmbiguousVariant`, `v`.`description`
FROM `tmp_ms_mc_preferred` AS `p`
JOIN `tmp_ms_mc_unique` AS `u` USING (`Entry`, `BaseItem`, `Band`)
JOIN `item_template` AS `v` ON `v`.`entry` = `p`.`Item`
WHERE `u`.`Candidates` > 1;
-- Counts include missing/ambiguous ranks in the 1-10 dungeon band.
SELECT `f`.`Entry`, `f`.`Label`, COUNT(DISTINCT `s`.`Item`) AS `BaseCandidates`,
    SUM(IF(`u`.`Candidates` = 1, 1, 0)) AS `UnambiguousVariants`,
    COUNT(DISTINCT `s`.`Item`) * IF(`f`.`Tier` = 'Band', 10, 1)
        - SUM(IF(`u`.`Candidates` = 1, 1, 0)) AS `UnresolvedVariants`
FROM `tmp_ms_mc_family` AS `f`
JOIN `tmp_ms_mc_source` AS `s` ON `s`.`Source` = `f`.`Source`
LEFT JOIN `tmp_ms_mc_unique` AS `u` ON `u`.`Entry` = `f`.`Entry` AND `u`.`BaseItem` = `s`.`Item`
GROUP BY `f`.`Entry`, `f`.`Label`, `f`.`Tier` ORDER BY `f`.`Entry`;
SELECT `Source`, COUNT(*) AS `BaseCandidates` FROM `tmp_ms_mc_source` GROUP BY `Source`;
SELECT `f`.`Entry`, `f`.`Label`, `f`.`Expected`, COUNT(`p`.`Item`) AS `Resolved`
FROM `tmp_ms_mc_family` AS `f` LEFT JOIN `tmp_ms_mc_pool` AS `p` USING (`Entry`)
GROUP BY `f`.`Entry`, `f`.`Label`, `f`.`Expected` ORDER BY `f`.`Entry`;

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_cache`;
CREATE TEMPORARY TABLE `tmp_ms_mc_cache` (
    `Entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `ExpectedRows` TINYINT UNSIGNED NOT NULL
) ENGINE=InnoDB;
INSERT INTO `tmp_ms_mc_cache` (`Entry`, `ExpectedRows`) VALUES
(1278056, 3), (1278058, 3), (1278060, 5), (1278061, 1),
(1278062, 1), (1278063, 1), (1278065, 1), (1278067, 1);

-- Persistent writes are transactional and follow all preflight checks.
-- Requires the recovered Ascension dataset, InnoDB loot tables and permission
-- to create a temporary migration procedure. SIGNAL is intentionally fatal.
DROP PROCEDURE IF EXISTS `ms_mc_reconstruct_20261003`;
DELIMITER $$
CREATE PROCEDURE `ms_mc_reconstruct_20261003`()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF @MS_OPTIONAL_FAMILY_PCT IS NULL OR @MS_OPTIONAL_FAMILY_PCT <= 0 OR @MS_OPTIONAL_FAMILY_PCT > 100
        OR @MS_SECOND_HEROIC_MC_PCT IS NULL OR @MS_SECOND_HEROIC_MC_PCT <= 0 OR @MS_SECOND_HEROIC_MC_PCT > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC cache reconstruction: invalid roll percentages';
    END IF;
    IF EXISTS (
        SELECT 1 FROM `tmp_ms_mc_family` AS `f`
        LEFT JOIN (SELECT `Entry`, COUNT(*) AS `N` FROM `tmp_ms_mc_pool` GROUP BY `Entry`) AS `p` USING (`Entry`)
        WHERE COALESCE(`p`.`N`, 0) <> `f`.`Expected` OR `f`.`Expected` = 0
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'MC cache reconstruction: pool count mismatch; inspect dataset/variant audit';
    END IF;
    IF (SELECT COUNT(*) FROM `item_template` AS `i` JOIN `tmp_ms_mc_cache` AS `c` ON `c`.`Entry` = `i`.`entry`
        WHERE (`i`.`Flags` & 4) <> 0 AND `i`.`ScriptName` = '') <> 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'MC cache reconstruction: expected eight scriptless HAS_LOOT containers';
    END IF;
    IF (SELECT COUNT(*) FROM `information_schema`.`TABLES`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` IN ('item_loot_template', 'reference_loot_template')
            AND `ENGINE` = 'InnoDB') <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC cache reconstruction: InnoDB loot tables required';
    END IF;
    IF EXISTS (SELECT 1 FROM `reference_loot_template` AS `r` JOIN `tmp_ms_mc_family` AS `f` USING (`Entry`)
        WHERE `r`.`Comment` NOT LIKE 'MS MC pool - %') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC cache reconstruction: reserved reference namespace collision';
    END IF;
    -- Separate statements avoid reopening tmp_ms_mc_family in one IF expression.
    IF EXISTS (SELECT 1 FROM `reference_loot_template` AS `r` JOIN `tmp_ms_mc_family` AS `f` ON `f`.`Entry` =
        `r`.`Reference`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC cache reconstruction: reserved reference namespace collision';
    END IF;
    IF EXISTS (SELECT 1 FROM `item_loot_template` AS `r` JOIN `tmp_ms_mc_family` AS `f` ON `f`.`Entry` =
        `r`.`Reference`
            LEFT JOIN `tmp_ms_mc_cache` AS `c` ON `c`.`Entry` = `r`.`Entry` WHERE `c`.`Entry` IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC cache reconstruction: reserved reference namespace collision';
    END IF;
    IF EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,9002010,
        9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `disenchant_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,
        9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `fishing_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,9002010,
        9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `gameobject_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,
        9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `mail_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,9002010,
        9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `milling_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,9002010,
        9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `pickpocketing_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,
        9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `prospecting_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,
        9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `skinning_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,
        9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `spell_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,9002010,
        9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR EXISTS (SELECT 1 FROM `player_loot_template` WHERE `Reference` IN (9002001,9002002,9002003,9002004,9002010,
        9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'MC cache reconstruction: reserved references used by another loot store';
    END IF;
    IF EXISTS (SELECT 1 FROM `conditions` WHERE (`SourceTypeOrReferenceId` = 10 AND `SourceGroup` IN (9002001,9002002,
        9002003,9002004,9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,9002043))
        OR (`SourceTypeOrReferenceId` = 5 AND `SourceGroup` IN (1278056,1278058,1278060,1278061,1278062,1278063,
        1278065,1278067))) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
        'MC cache reconstruction: existing loot conditions require manual review';
    END IF;
    START TRANSACTION;
    DELETE `r` FROM `reference_loot_template` AS `r` JOIN `tmp_ms_mc_family` AS `f` USING (`Entry`);
    INSERT INTO `reference_loot_template`
        (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
        `Comment`)
    SELECT `p`.`Entry`, `p`.`Item`, 0, 0, 0, 1, 1, 1, 1, CONCAT('MS MC pool - ', `f`.`Label`)
    FROM `tmp_ms_mc_pool` AS `p` JOIN `tmp_ms_mc_family` AS `f` USING (`Entry`);
    DELETE `r` FROM `item_loot_template` AS `r` JOIN `tmp_ms_mc_cache` AS `c` USING (`Entry`);
    INSERT INTO `item_loot_template`
        (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
        `Comment`)
    VALUES
    (1278056, 1, 9002022, 100, 0, 1, 0, 1, 1, 'MS MC: guaranteed Mythic ZG'),
    (1278056, 2, 9002001, 100, 0, 1, 0, 1, 1, 'MS MC: guaranteed Normal MC'),
    (1278056, 3, 9002030, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 0, 1, 1, 'MS MC: additional Classic Mythic dungeon'),
    (1278058, 1, 9002001, 100, 0, 1, 0, 1, 1, 'MS MC: guaranteed Normal MC'),
    (1278058, 2, 9002002, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 0, 1, 1, 'MS MC: additional Heroic MC'),
    (1278058, 3, 9002030, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 0, 1, 1, 'MS MC: additional Classic Mythic dungeon'),
    (1278060, 1, 9002002, 100, 0, 1, 0, 1, 1, 'MS MC: guaranteed Heroic MC'),
    (1278060, 2, 9002002, @MS_SECOND_HEROIC_MC_PCT, 0, 1, 0, 1, 1, 'MS MC: optional second Heroic MC (1-2)'),
    (1278060, 3, 9002003, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 0, 1, 1, 'MS MC: additional Mythic MC'),
    (1278060, 4, 9002010, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 0, 1, 1, 'MS MC: additional Normal Onyxia'),
    (1278060, 5, 9002031, @MS_OPTIONAL_FAMILY_PCT, 0, 1, 0, 1, 1, 'MS MC: additional Classic Mythic 1-10'),
    (1278061, 1, 9002040, 100, 0, 1, 0, 1, 1, 'MS MC: reconstructed Normal MC/Onyxia union'),
    (1278062, 1, 9002004, 100, 0, 1, 0, 1, 1, 'MS MC: reconstructed Ascended MC'),
    (1278063, 1, 9002041, 100, 0, 1, 0, 1, 1, 'MS MC: reconstructed Heroic MC/Onyxia union'),
    (1278065, 1, 9002042, 100, 0, 1, 0, 1, 1, 'MS MC: reconstructed Mythic MC/Onyxia union'),
    (1278067, 1, 9002043, 100, 0, 1, 0, 1, 1, 'MS MC: reconstructed Ascended MC/Onyxia union');
    IF EXISTS (SELECT 1 FROM `tmp_ms_mc_cache` AS `c`
        LEFT JOIN (SELECT `Entry`, COUNT(*) AS `N` FROM `item_loot_template` GROUP BY `Entry`) AS `r` USING (`Entry`)
        WHERE COALESCE(`r`.`N`, 0) <> `c`.`ExpectedRows`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC cache reconstruction: physical row count mismatch';
    END IF;
    COMMIT;
END$$
DELIMITER ;
CALL `ms_mc_reconstruct_20261003`();
DROP PROCEDURE `ms_mc_reconstruct_20261003`;

-- Post-write validation: 16 physical rows across all 8 caches; 15 pure leaves.
SELECT `r`.* FROM `item_loot_template` AS `r` JOIN `tmp_ms_mc_cache` AS `c` USING (`Entry`)
ORDER BY `r`.`Entry`, `r`.`Item`;
SELECT `f`.`Entry`, `f`.`Label`, `f`.`Expected`, COUNT(`r`.`Item`) AS `Installed`
FROM `tmp_ms_mc_family` AS `f` LEFT JOIN `reference_loot_template` AS `r` USING (`Entry`)
GROUP BY `f`.`Entry`, `f`.`Label`, `f`.`Expected` ORDER BY `f`.`Entry`;
-- Must return no rows: invalid containers/references, non-equipment leaves,
-- duplicate candidates, or conditions that would invalidate personalization.
SELECT `r`.* FROM `item_loot_template` AS `r` JOIN `tmp_ms_mc_cache` AS `c` USING (`Entry`)
LEFT JOIN `tmp_ms_mc_family` AS `f` ON `f`.`Entry` = `r`.`Reference`
WHERE `f`.`Entry` IS NULL OR `r`.`GroupId` <> 0 OR `r`.`Chance` <= 0
    OR `r`.`MinCount` <> 1 OR `r`.`MaxCount` <> 1;
SELECT `r`.* FROM `reference_loot_template` AS `r` JOIN `tmp_ms_mc_family` AS `f` USING (`Entry`)
LEFT JOIN `item_template` AS `i` ON `i`.`entry` = `r`.`Item`
WHERE `i`.`entry` IS NULL OR `i`.`class` NOT IN (2, 4) OR `i`.`InventoryType` = 0
    OR `i`.`RequiredLevel` > 60 OR `r`.`Reference` <> 0 OR `r`.`GroupId` <> 1 OR `r`.`Chance` <> 0;
SELECT `r`.`Entry`, `r`.`Item`, COUNT(*) AS `Duplicates`
FROM `reference_loot_template` AS `r` JOIN `tmp_ms_mc_family` AS `f` USING (`Entry`)
GROUP BY `r`.`Entry`, `r`.`Item` HAVING COUNT(*) <> 1;
SELECT `c`.* FROM `conditions` AS `c`
WHERE (`c`.`SourceTypeOrReferenceId` = 10 AND `c`.`SourceGroup` IN
    (9002001,9002002,9002003,9002004,9002010,9002011,9002012,9002013,9002022,9002030,9002031,9002040,9002041,9002042,
        9002043))
    OR (`c`.`SourceTypeOrReferenceId` = 5 AND `c`.`SourceGroup` IN
    (1278056,1278058,1278060,1278061,1278062,1278063,1278065,1278067));

DROP TEMPORARY TABLE `tmp_ms_mc_cache`;
DROP TEMPORARY TABLE `tmp_ms_mc_combined`;
DROP TEMPORARY TABLE `tmp_ms_mc_pool`;
DROP TEMPORARY TABLE `tmp_ms_mc_unique`;
DROP TEMPORARY TABLE `tmp_ms_mc_preferred`;
DROP TEMPORARY TABLE `tmp_ms_mc_priority`;
DROP TEMPORARY TABLE `tmp_ms_mc_matches`;
DROP TEMPORARY TABLE `tmp_ms_mc_variant`;
DROP TEMPORARY TABLE `tmp_ms_mc_family`;
DROP TEMPORARY TABLE `tmp_ms_mc_source`;
