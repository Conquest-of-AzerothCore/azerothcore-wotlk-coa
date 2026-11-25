-- Restore the original level-60 Mythic damage budgets for Ramparts bosses and their forms.
UPDATE `coa_dungeon_rescale_budget`
SET `melee_multiplier` = CASE `entry`
        WHEN 17306 THEN 0.6
        WHEN 17307 THEN 2.0
        WHEN 17308 THEN 1.75
        WHEN 17536 THEN 0.73
        WHEN 17537 THEN 1.325
    END,
    `spell_multiplier` = 2
WHERE `map_id` = 543 AND `difficulty` = 2 AND `entry` IN (17306, 17307, 17308, 17536, 17537);
