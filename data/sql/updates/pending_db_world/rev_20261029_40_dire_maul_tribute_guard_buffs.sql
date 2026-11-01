-- Dire Maul North tribute run: Guard Fengus, Guard Slip'kik and Guard Mol'dar buff the new King of the Gordok from
-- their gossip option. rev_20261004_90_dungeon_boss_smart_scripts switched their vanilla rows off with event flag
-- 0x10 (never in 5-man dungeons) to make room for the Ascension kit, the gossip select rows included, so the option
-- closed without a buff (#9414). The gossip rows are not combat abilities and run again on every difficulty.
UPDATE `smart_scripts` SET `event_flags` = `event_flags` & ~16
WHERE `source_type` = 0 AND `event_type` = 62 AND (`entryorguid`, `id`) IN ((14321, 7), (14323, 14), (14326, 7));
