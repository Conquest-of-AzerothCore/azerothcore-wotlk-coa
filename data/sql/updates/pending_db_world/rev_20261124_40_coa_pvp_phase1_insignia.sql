-- The phase 1 Challenger's vendors sell the faction Insignia, which no spawned vendor offered while
-- Ascension.PvPVendors.ReleaseStage is 1. The db.exil.es npc_vendor table (SUB dump of 2026-10-04) lists Captain
-- Korgash 49051 with Insignia of the Horde 1118852; Lieutenant Thorne 48052 has no captured rows and sells
-- Insignia of the Alliance 1118864 by analogy. Both cost 10000 honor (165), the price of the phase 2 Challenger's
-- submenus 9480534 and 9490534. The item level 20 Insignia 1118853 and 1118863 have no captured honor price; they
-- cost 1000 honor (883), the price of the item level 57 Challenger's accessories, by maintainer decision.
DELETE FROM `npc_vendor` WHERE (`entry` = 48052 AND `item` IN (1118863, 1118864))
    OR (`entry` = 49051 AND `item` IN (1118852, 1118853));
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(48052, 61, 1118864, 0, 0, 165, NULL),
(48052, 62, 1118863, 0, 0, 883, NULL),
(49051, 61, 1118852, 0, 0, 165, NULL),
(49051, 62, 1118853, 0, 0, 883, NULL);
