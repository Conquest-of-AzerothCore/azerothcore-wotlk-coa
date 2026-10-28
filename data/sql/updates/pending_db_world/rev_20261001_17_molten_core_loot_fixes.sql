-- K2: Molten Core loot corrections (diag-K-loot.md / diag-K-loot-export.md).
-- Late-sorting on purpose: rev_20260930_80_molten_core_loot.sql regenerates the full MC loot set
-- and would re-apply its own regressions on a fresh slot if a later file didn't restate the fix.

-- (a) "Personal Cache" (1170083) is a non-functional modern weekly-cache token carried in from the
-- live Ascension economy export: no item_template row backs its name, and its on-use spell (93461)
-- is a bare dummy with no opener script bound anywhere in this repo. Remove it from all 9 MC
-- scheduled bosses, on every difficulty (36 rows).
DELETE FROM `creature_loot_template`
WHERE `Entry` IN (11502,111502,211502,311502, 11982,111982,211982,311982,
                   11988,111988,211988,311988, 12056,112056,212056,312056,
                   12057,112057,212057,312057, 12098,112098,212098,312098,
                   12118,112118,212118,312118, 12259,112259,212259,312259,
                   12264,112264,212264,312264)
  AND `Item` = 1170083;

-- (b) rev_20260930_80's export-driven regen silently dropped 4 Fiery Core (17010) / Lava Core
-- (17011) rows that base (currently-shipped) creature_loot_template already had on Flameguard,
-- Golemagg, Baron Geddon and Garr. Re-add them at base's own chance, then replicate every
-- Fiery/Lava Core row (the 7 export-matched entries + these 4) onto its +100000/+200000/+300000
-- variants, unchanged chance (no new rate invented; rates are a separate, user-pending decision).
DELETE FROM `creature_loot_template` WHERE `Item` IN (17010, 17011) AND `Entry` IN (
    11659,111659,211659,311659,
    11665,111665,211665,311665,
    11666,111666,211666,311666,
    11667,111667,211667,311667,
    11668,111668,211668,311668,
    11988,111988,211988,311988,
    12056,112056,212056,312056,
    12057,112057,212057,312057,
    12076,112076,212076,312076,
    12100,112100,212100,312100,
    12101,112101,212101,312101);

INSERT INTO `creature_loot_template` (`Entry`,`Item`,`Reference`,`Chance`,`QuestRequired`,`LootMode`,`GroupId`,`MinCount`,`MaxCount`,`Comment`) VALUES
-- Molten Destroyer (11659) already had both items on Normal; replicate onto variants
(11659,17010,0,14.905,0,1,0,1,1,'Molten Destroyer - Fiery Core'),
(111659,17010,0,14.905,0,1,0,1,1,'Molten Destroyer - Fiery Core'),
(211659,17010,0,14.905,0,1,0,1,1,'Molten Destroyer - Fiery Core'),
(311659,17010,0,14.905,0,1,0,1,1,'Molten Destroyer - Fiery Core'),
(11659,17011,0,15.38,0,1,0,1,1,'Molten Destroyer - Lava Core'),
(111659,17011,0,15.38,0,1,0,1,1,'Molten Destroyer - Lava Core'),
(211659,17011,0,15.38,0,1,0,1,1,'Molten Destroyer - Lava Core'),
(311659,17011,0,15.38,0,1,0,1,1,'Molten Destroyer - Lava Core'),
-- Lava Annihilator (11665): Lava Core only
(11665,17011,0,12.4584,0,1,0,1,1,'Lava Annihilator - Lava Core'),
(111665,17011,0,12.4584,0,1,0,1,1,'Lava Annihilator - Lava Core'),
(211665,17011,0,12.4584,0,1,0,1,1,'Lava Annihilator - Lava Core'),
(311665,17011,0,12.4584,0,1,0,1,1,'Lava Annihilator - Lava Core'),
-- Firewalker (11666): Fiery Core only
(11666,17010,0,42.233,0,1,0,1,1,'Firewalker - Fiery Core'),
(111666,17010,0,42.233,0,1,0,1,1,'Firewalker - Fiery Core'),
(211666,17010,0,42.233,0,1,0,1,1,'Firewalker - Fiery Core'),
(311666,17010,0,42.233,0,1,0,1,1,'Firewalker - Fiery Core'),
-- Flameguard (11667): base-data regression, Fiery Core only
(11667,17010,0,34.7337,0,1,0,1,1,'Flameguard - Fiery Core'),
(111667,17010,0,34.7337,0,1,0,1,1,'Flameguard - Fiery Core'),
(211667,17010,0,34.7337,0,1,0,1,1,'Flameguard - Fiery Core'),
(311667,17010,0,34.7337,0,1,0,1,1,'Flameguard - Fiery Core'),
-- Firelord trash (11668): Fiery Core only
(11668,17010,0,23.4358,0,1,0,1,1,'Firelord - Fiery Core'),
(111668,17010,0,23.4358,0,1,0,1,1,'Firelord - Fiery Core'),
(211668,17010,0,23.4358,0,1,0,1,1,'Firelord - Fiery Core'),
(311668,17010,0,23.4358,0,1,0,1,1,'Firelord - Fiery Core'),
-- Golemagg (11988): base-data regression, Lava Core only
(11988,17011,0,14,0,1,0,1,1,'Golemagg the Incinerator - Lava Core'),
(111988,17011,0,14,0,1,0,1,1,'Golemagg the Incinerator - Lava Core'),
(211988,17011,0,14,0,1,0,1,1,'Golemagg the Incinerator - Lava Core'),
(311988,17011,0,14,0,1,0,1,1,'Golemagg the Incinerator - Lava Core'),
-- Garr (12057): base-data regression, Lava Core only
(12057,17011,0,14,0,1,0,1,1,'Garr - Lava Core'),
(112057,17011,0,14,0,1,0,1,1,'Garr - Lava Core'),
(212057,17011,0,14,0,1,0,1,1,'Garr - Lava Core'),
(312057,17011,0,14,0,1,0,1,1,'Garr - Lava Core'),
-- Baron Geddon (12056): base-data regression, Fiery Core only
(12056,17010,0,14,0,1,0,1,1,'Baron Geddon - Fiery Core'),
(112056,17010,0,14,0,1,0,1,1,'Baron Geddon - Fiery Core'),
(212056,17010,0,14,0,1,0,1,1,'Baron Geddon - Fiery Core'),
(312056,17010,0,14,0,1,0,1,1,'Baron Geddon - Fiery Core'),
-- Lava Elemental (12076): Lava Core only
(12076,17011,0,23.8429,0,1,0,1,1,'Lava Elemental - Lava Core'),
(112076,17011,0,23.8429,0,1,0,1,1,'Lava Elemental - Lava Core'),
(212076,17011,0,23.8429,0,1,0,1,1,'Lava Elemental - Lava Core'),
(312076,17011,0,23.8429,0,1,0,1,1,'Lava Elemental - Lava Core'),
-- Lava Reaver (12100): Lava Core only
(12100,17011,0,22.0638,0,1,0,1,1,'Lava Reaver - Lava Core'),
(112100,17011,0,22.0638,0,1,0,1,1,'Lava Reaver - Lava Core'),
(212100,17011,0,22.0638,0,1,0,1,1,'Lava Reaver - Lava Core'),
(312100,17011,0,22.0638,0,1,0,1,1,'Lava Reaver - Lava Core'),
-- Lava Surger (12101): Lava Core only
(12101,17011,0,3.4843,0,1,0,1,1,'Lava Surger - Lava Core'),
(112101,17011,0,3.4843,0,1,0,1,1,'Lava Surger - Lava Core'),
(212101,17011,0,3.4843,0,1,0,1,1,'Lava Surger - Lava Core'),
(312101,17011,0,3.4843,0,1,0,1,1,'Lava Surger - Lava Core');

-- (c) Hands of the Enemy (quest 6824) turn-in items must stay QuestRequired=1 on every difficulty,
-- as base data already has them; rev_20260930_80's export-driven regen dropped it to 0 on all 4
-- items x 4 difficulties (16 rows), making them drop unconditionally for everyone.
UPDATE `creature_loot_template` SET `QuestRequired` = 1
WHERE (`Entry`, `Item`) IN
  ((12118,17329),(112118,17329),(212118,17329),(312118,17329),   -- Hand of Lucifron
   (12098,17330),(112098,17330),(212098,17330),(312098,17330),   -- Hand of Sulfuron
   (12259,17331),(112259,17331),(212259,17331),(312259,17331),   -- Hand of Gehennas
   (12264,17332),(112264,17332),(212264,17332),(312264,17332));  -- Hand of Shazzrah

-- (d) Cache of the Fire Lord (2400040, Ragnaros Heroic/Mythic) is left unchanged on purpose: its
-- contents have no evidence anywhere (export, DBC, item_loot_template) and are a maintainer
-- decision pending, per diag-K-loot.md item (b). Not touched here.
