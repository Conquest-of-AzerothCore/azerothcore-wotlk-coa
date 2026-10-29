-- Apex bosses: shared quest loot.
-- Without CREATURE_TYPE_FLAG_QUEST_BOSS the hide is a normal quest item on the
-- creature's single loot window, so only the first party member can take it and
-- the rest of the group leaves empty. The flag turns the bosses into shared
-- quest targets: every eligible participant gets their own free-for-all hide.
UPDATE `creature_template`
SET `type_flags` = `type_flags` | 0x80000000
WHERE `entry` IN (9916222, 9916223, 9916224);
