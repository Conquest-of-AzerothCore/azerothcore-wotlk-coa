-- Verog the Dervish (#7898): the quest log tells the player to kill enough centaurs at the
-- Stagnant Oasis command tent until they raise the alarm. The old per-death summon rows are
-- removed entirely; the quest script in zone_the_barrens.cpp counts ten Kolkar kills near the
-- tent for a player on quest 851 and then summons Verog at the tent. (A zero percent chance
-- would not disable the roll in SmartAI - a zero chance row always fires.)

DELETE FROM `smart_scripts`
WHERE (`entryorguid` = 3274 AND `source_type` = 0 AND `id` IN (1, 2))
   OR (`entryorguid` = 3275 AND `source_type` = 0 AND `id` IN (1, 2))
   OR (`entryorguid` = 3397 AND `source_type` = 0 AND `id` IN (2, 3));
