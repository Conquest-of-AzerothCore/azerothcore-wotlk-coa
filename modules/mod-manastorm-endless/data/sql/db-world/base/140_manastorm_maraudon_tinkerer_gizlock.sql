-- Maraudon / Tinkerer Gizlock (native NPC 13601, map 349).
--
-- Original recovered Ascension Manastorm encounter identities:
--   681 = Normal  (difficulty 0), dungeon encounter  427
--   682 = Endgame (difficulty 2), dungeon encounter 2427
-- No duplicate historical Gizlock routes were recovered.
--
-- Exact player-authored arrival teleport:
--   game_tele 2177, X 313.166, Y -339.761, Z -117.146,
--   orientation 4.59221, map 349,
--   name 'Manastorm_Maraudon_TinkererGizlock'
--
-- The native instance_maraudon.cpp has no Gizlock activation,
-- door, or summoning prerequisite. Retain his original native
-- world-DB spawn and combat AI, and do not modify public Maraudon.
--
-- Rerunnable migration, scoped only to two recovered segment IDs.
-- Preserve existing user-configured Chaotic Link candidate rosters
-- and stack counts, weights, depths, rewards, and unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2177, 313.166, -339.761, -117.146, 4.59221, 349,
     'Manastorm_Maraudon_TinkererGizlock');

-- Enable exactly one original route per difficulty, sharing the
-- player-authored teleport. OR StartingUnlocked (0x1) to keep
-- any additional flag bits intact.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2177,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 681
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 427
     AND `objective_creature_entry` = 13601
     AND `start_game_tele_id` IN (0, 2177))
 OR (`segment_id` = 682
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2427
     AND `objective_creature_entry` = 13601
     AND `start_game_tele_id` IN (0, 2177));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        weight, chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (681, 682)
-- ORDER BY difficulty, segment_id;
