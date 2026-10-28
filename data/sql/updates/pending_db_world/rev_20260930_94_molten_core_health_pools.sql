-- Molten Core coa_boss_flex health pools, rebuilt from the user's own video readings
-- (MC_PV Video 1/2 "Bronzebeard values", Video 3 "CoA Values" -- Bronzebeard (BB) is the earlier
-- Ascension realm with classic classes, CoA is Conquest of Azeroth; CoA classes deal much more
-- DPS, hence much more boss health). Method, full per-entity table and the two coefficients used
-- are written out in docs/coa/molten-core.md Sec.5 and .agents/plans/mc-restoration/hp/hp-pools.md
-- (gitignored working notes); short version:
--
--   * A CoA video reading, divided by its own "Eff." player count, is used directly wherever one
--     exists (Lucifron, Magmadar, Gehennas, Garr, Baron Geddon, Sulfuron Harbinger, Corvus the
--     Nimble, Ragnaros Normal+Ascended, Lesser Son of Flame Ascended).
--   * Where a boss has a direct CoA reading for one difficulty only, the others are filled in
--     using that same boss's own current coa_boss_flex hp_d0:d1:d2:d3 shape, anchored on the new
--     measured value(s) -- not the generic 1.44/1.88/2.32 trash ladder, since these bosses already
--     carry their own measured per-difficulty structure.
--   * Two bosses (Golemagg, Majordomo) have no video reading of their own and never did (their
--     existing rows were themselves derived, not measured) -- their whole row is rescaled by
--     K = 1.3645 (average of CoA-video / current-hp_d3 for the six bosses that do have a direct
--     Ascended reading: Lucifron 1.363, Garr 1.365, Gehennas 1.365, Geddon 1.365, Sulfuron 1.363,
--     Magmadar 1.365 -- a tight cluster, read as one global "BB-log-derived design -> real CoA
--     video" rescale for this boss family).
--   * Shazzrah has no CoA reading but does have a BB video reading (Ascended, 15.092M/22 players);
--     reconstructed as that BB per-player figure x C = 3.306 (the CoA/BB ratio averaged over Garr,
--     Baron Geddon and Gehennas, the three bosses with both a BB and a CoA video reading; Magmadar's
--     own BB/CoA pair gives an outlier 3.14 and is excluded from the average -- see the plan notes).
--     The two independent estimates for Shazzrah (BB x C = 2.268M, and current-design x K = 2.261M)
--     land within 0.3% of each other, cross-confirming the method.
--   * All trash/adds with no CoA reading (every trash type; no CoA video gives one) are
--     reconstructed the same way: the BB video reading (all at the Mythic tier, d2) x C gives the
--     Ascended-equivalent CoA figure, then Normal/Heroic/Mythic follow the client-cache trash ratio
--     1 : 1.44 : 1.88 : 2.32 already used for their flat (non-flex) HealthModifier in rev_20260930_81.
--   * Shadow of Lucifron (12268) has its own BB video reading (Mythic, 2.85M/25 players) and is
--     rebuilt the same trash-ratio way, replacing rev_20260930_92's 25%-of-Lucifron placeholder.
--   * Trash entities with no reading anywhere (Lava Spawn 12265, Flamewaker Protector 12119) are
--     left unflexed -- no coa_boss_flex row is added for them; they keep the flat HealthModifier
--     from rev_20260930_81. Three CoA-only named adds seen in the video (Cull the Destroyer,
--     "Proxima the Opressor", Ebon the Cruel -- export ids 92031/92032/92033) and two more
--     CoA-only Son of Flame variants (Son of Flame 92026, Greater Son of Flame 92027) plus
--     "Sacrificial Chains" (92030) exist only as health_min/max=1, level-1 placeholder rows in the
--     db.exil.es export (creature.csv.gz) -- none of the six has a `creature_template` row on this
--     fork at all, so none is currently spawned; their computed health figures are recorded in
--     hp-pools.md for whoever wires them up, not inserted here.
--
-- creature_template.HealthModifier (Normal absolute health, set in rev_20260930_81 from the
-- export) is left untouched for every entry below: FlexHealth.cpp's OnCreatureSelectLevel hook
-- overrides it immediately at spawn for any creature whose base entry has a coa_boss_flex row in a
-- raid map, so the static HealthModifier is inert for all of them regardless of its value; keeping
-- it as the export's own absolute-health figure avoids mixing two different data sources for the
-- same field.
--
-- Magmadar's own row is also given to both head creatures (80642/80643) unchanged, rather than a
-- split -- see the C++ change in boss_magmadar_coa.cpp (heads now mirror the body's health instead
-- of holding their own fraction of it); this SQL only needs to stop dividing the total.

DELETE FROM `coa_boss_flex` WHERE `entry` IN (
  11502, 11658, 11659, 11662, 11663, 11664, 11665, 11666, 11667, 11668, 11669, 11671, 11672, 11673,
  11982, 11988, 12018, 12056, 12057, 12076, 12098, 12100, 12101, 12118, 12143, 12259, 12264, 12268,
  80642, 80643
);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(12118, 588759, 785012, 1181513, 1722727, 'Lucifron: CoA video Ascended (37.9M/22 players); d0-d2 = own prior hp_d0:d1:d2 shape anchored on the new d3'),
(12259, 884118, 1178824, 1774235, 2586957, 'Gehennas: CoA video Ascended (59.5M/23); d0-d2 = own prior shape anchored on the new d3'),
(12057, 1105520, 1474027, 2218539, 3234783, 'Garr: CoA video Ascended (74.4M/23); d0-d2 = own prior shape anchored on the new d3'),
(12264, 775397, 1033863, 1556054, 2267615, 'Shazzrah: no CoA video; BB video Ascended (15.092M/22) x C=3.306, d0-d2 = own prior shape anchored on the new d3'),
(12056, 884285, 1179047, 1774570, 2586957, 'Baron Geddon: CoA video Ascended (59.5M/23); d0-d2 = own prior shape anchored on the new d3'),
(12098, 441316, 588422, 885626, 1291304, 'Sulfuron Harbinger: CoA video Ascended (29.7M/23); d0-d2 = own prior shape anchored on the new d3'),
(11988, 1104793, 1473058, 2217081, 3232656, 'Golemagg the Incinerator: no CoA/BB video of its own; own prior row x K=1.3645 (global CoA/current-design rescale)'),
(11982, 1105520, 1474027, 2218539, 3234783, 'Magmadar: CoA video Ascended (74.4M/23); d0-d2 = own (=Golemagg''s) prior shape anchored on the new d3; heads (80642/80643) below mirror this row unchanged'),
(80642, 1105520, 1474027, 2218539, 3234783, 'Magmadar''s Right Head: mirrors the body''s row (MC_PV video: heads always read the same figure as Magmadar, "PV = Magmadar") -- damage is redirected to the body in boss_magmadar_coa.cpp, this row only sizes the shared pool'),
(80643, 1105520, 1474027, 2218539, 3234783, 'Magmadar''s Left Head: mirrors the body''s row, same reasoning as the right head'),
(12018, 890963, 1187950, 1787968, 2606980, 'Majordomo Executus: no CoA/BB video of its own; own prior row x K=1.3645 (global CoA/current-design rescale)'),
(11502, 2394118, 3192157, 4747960, 7058824, 'Ragnaros: CoA video Normal (20.3M/17, 50% of his 40.7M total) and Ascended (60M/17, 50% of his 120M total) are both direct readings; d1/d2 = own prior d1/d0, d2/d0 ratios anchored on the new d0 (his own Heroic-Mythic-Ascended pattern differs from the boss family''s, see the plan notes on his x2.86 scale vs the family''s x1.365) -- he starts the fight at 50% health, applied in boss_ragnaros.cpp, not by halving this table'),
(12268, 200444, 288639, 376834, 465029, 'Shadow of Lucifron: BB video Mythic (2.85M/25) -> d0 via /1.88, x C=3.306, then the trash ratio 1:1.44:1.88:2.32; replaces rev_20260930_92''s 25%-of-Lucifron placeholder with a measured figure'),
(11662, 121814, 175412, 229010, 282609, 'Corvus the Nimble (Flamewaker Priest): CoA video Ascended (6.5M/23); d0-d2 via the trash ratio 1:1.44:1.88:2.32 (never flexed before, no prior shape of its own)'),
(12143, 53245, 76673, 100101, 123529, 'Lesser Son of Flame: CoA video Ascended (2.1M/17); d0-d2 via the trash ratio 1:1.44:1.88:2.32; newly flexed (previously static HealthModifier only)'),
(11673, 87174, 125530, 163886, 202243, 'Ancient Core Hound: BB video Mythic (942K/19) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11671, 20359, 29317, 38275, 47233, 'Core Hound: BB video Mythic (220K/19) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11668, 33777, 48640, 63502, 78364, 'Firelord (trash): BB video Mythic (365K/19) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11666, 16784, 24168, 31553, 38938, 'Firewalker: BB video Mythic (210K/22) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11669, 3887, 5597, 7307, 9017, 'Flame Imp: BB video Mythic (42K/19) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11667, 16784, 24168, 31553, 38938, 'Flameguard: BB video Mythic (210K/22), same reading as Firewalker -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11665, 42384, 61033, 79681, 98330, 'Lava Annihilator: BB video Mythic (458K/19) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(12076, 20780, 29923, 39066, 48209, 'Lava Elemental: BB video Mythic (260K/22) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(12100, 16784, 24168, 31553, 38938, 'Lava Reaver: BB video Mythic (210K/22), same reading as Firewalker -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(12101, 42384, 61033, 79681, 98330, 'Lava Surger: BB video Mythic (458K/19), same reading as Lava Annihilator -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11659, 133964, 192908, 251852, 310796, 'Molten Destroyer: BB video Mythic (1.6M/21) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11658, 133964, 192908, 251852, 310796, 'Molten Giant: BB video Mythic (1.6M/21), same reading as Molten Destroyer -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11664, 176267, 253825, 331383, 408940, 'Flamewaker Elite: BB video Mythic (2.406M/24) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11663, 176267, 253825, 331383, 408940, 'Flamewaker Acolyte (Healer): BB video Mythic (2.406M/24), same reading as Flamewaker Elite -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32'),
(11672, 65056, 93681, 122306, 150931, 'Cindermaw (Core Rager): BB video Mythic (740K/20) -> d0 via /1.88, x C=3.306, then 1:1.44:1.88:2.32');
