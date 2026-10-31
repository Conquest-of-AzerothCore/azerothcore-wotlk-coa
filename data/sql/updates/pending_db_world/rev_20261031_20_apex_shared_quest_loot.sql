-- Apex bosses: party-shareable hides and normal respawn behaviour.
--
-- The hide is a quest item, so without ITEM_FLAG_MULTI_DROP only the first
-- player can loot it and the rest of the group leaves empty. The multi-drop
-- flag makes the loot item free-for-all: every party member with the hunt can
-- take their own copy, and the item is not removed from the corpse by the first
-- loot. The hide item flags are only touched here; creature flags are left
-- alone because CREATURE_TYPE_FLAG_QUEST_BOSS also changes the creature's
-- respawn timer behaviour (shared quest targets get a shortened death-based
-- respawn), which broke `.respawn` for the apex bosses.
UPDATE `item_template`
SET `flags` = `flags` | 0x800
WHERE `entry` IN (1009302, 1009303, 1009304);

-- Undo an earlier application of the quest-boss flag on the apex creatures.
UPDATE `creature_template`
SET `type_flags` = `type_flags` & ~0x80000000
WHERE `entry` IN (9916222, 9916223, 9916224);
