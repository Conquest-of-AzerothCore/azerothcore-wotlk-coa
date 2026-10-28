-- Farmer Saldean (233) kept offering the two older "The Killing Fields" quests (9: Harvest Watchers,
-- 17014: Harvest Reapers) next to the chained replacement 26995 -> 26996 -> 26997 (golems, Watchers, Reapers).
-- Stop offering the older pair so the chain is taken in order. The quest enders stay, so characters that
-- already accepted 9 or 17014 can still turn them in.
DELETE FROM `creature_queststarter` WHERE `id` = 233 AND `quest` IN (9, 17014);
