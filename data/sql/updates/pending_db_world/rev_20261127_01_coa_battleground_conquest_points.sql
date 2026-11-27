-- Classic Battleground reward quests pay live CoA Conquest (Arena) Points: AscensionDB client captures (190005
-- 2026-08-31, 190012 2026-09-04), SUB db.exil.es dump 2026-10-04 quest.reward_arena_points, Rexxar questcache.wdb
-- 2026-09-05. Losses below level 60 stay 0.
UPDATE `quest_template` SET `RewardArenaPoints` = CASE `ID`
    WHEN 190005 THEN 500
    WHEN 190012 THEN 200
    WHEN 90005 THEN 50
    ELSE 25
END
WHERE `ID` IN (90001, 90002, 90003, 90004, 90005, 190005, 190012);
