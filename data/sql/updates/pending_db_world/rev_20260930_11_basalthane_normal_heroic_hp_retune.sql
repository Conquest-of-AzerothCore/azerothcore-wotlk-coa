-- rev_20260925_32 retuned Mythic (7092) and Ascended (9662) HealthModifier
-- but left Normal (5355) and Heroic (11228) untouched "pending more data" --
-- by the file's own formula (total = 5527 x HealthModifier), that left
-- Heroic at ~62.1M total, HIGHER than both Mythic (~39.2M) and Ascended
-- (~53.4M) -- backwards difficulty ordering.
--
-- Now have real per-player data from four actual Basalthane kills (see
-- rev_20260925_02_basalthane_boss_flex.sql's corrected values). This raw
-- HealthModifier total is a fallback path (coa_boss_flex overrides it
-- whenever flex is active on a raid map), but the fallback should still be
-- correctly ordered. Retuned Normal and Heroic using the same real
-- measured per-player ratios the flex fix used, anchored on Mythic's
-- already-correct value:
--   Heroic  = 7092 x (1,936,186 / 2,878,908) = 4770 -> 26,363,790 total
--   Normal  = 4770 x (1,175,972 / 1,936,186) = 2897 -> 16,011,719 total
-- Resulting order: Normal 16.0M < Heroic 26.4M < Mythic 39.2M < Ascended 53.4M.

UPDATE `creature_template` SET `HealthModifier` = 2897 WHERE `entry` = 10189;
UPDATE `creature_template` SET `HealthModifier` = 4770 WHERE `entry` = 10190;
