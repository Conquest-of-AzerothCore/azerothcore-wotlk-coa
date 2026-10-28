-- Basalthane's Mythic/Ascended HealthModifier were WAY too high in practice
-- (confirmed live via .npc info 2026-09-25: Mythic showed 74,421,056 HP,
-- Ascended 86,782,427). Root cause: creature_classlevelstats for level 63
-- class 1 has basehp2=1 (placeholder -- Wrath-tier data only starts at
-- level 68 in stock AzerothCore). ObjectMgr::LoadCreatureClassLevelStats
-- (the "xinef: if no data is available, get them from lower expansions"
-- fallback) fills that placeholder from basehp1=5527 instead of using 1.
-- So Basalthane's real total HP is 5527 x HealthModifier, not
-- 1 x HealthModifier as the raw creature_template value alone suggests.
--
-- User-supplied targets (from CoA source Discord data), total HP at 20
-- players (no flex is active for Basalthane -- confirmed 2026-09-25):
--   Mythic:   ~39.2M  -> HealthModifier = 39200000 / 5527 = 7092 (39,197,484 actual)
--   Ascended: ~53.4M  -> HealthModifier = 53400000 / 5527 = 9662 (53,401,874 actual)
-- Normal (10185) and Heroic (10186) left untouched, pending more data.

UPDATE `creature_template` SET `HealthModifier` = 7092 WHERE `entry` = 10187;
UPDATE `creature_template` SET `HealthModifier` = 9662 WHERE `entry` = 10188;
