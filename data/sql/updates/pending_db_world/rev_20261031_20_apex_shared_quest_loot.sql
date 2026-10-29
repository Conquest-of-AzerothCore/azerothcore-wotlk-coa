-- Apex bosses: shared quest loot.
-- Without CREATURE_TYPE_FLAG_QUEST_BOSS the hide is a normal quest item on the
-- creature's single loot window, so only the first party member can take it and
-- the rest of the group leaves empty. The flag turns the bosses into shared
-- quest targets: every eligible participant gets their own free-for-all hide.
UPDATE `creature_template`
SET `type_flags` = `type_flags` | 0x80000000
WHERE `entry` IN (9916222, 9916223, 9916224);

-- The multi-drop item flag keeps the hide available after one player loots it,
-- so every member of the party can take their own copy.
UPDATE `item_template`
SET `flags` = `flags` | 0x800
WHERE `entry` IN (1009302, 1009303, 1009304);
