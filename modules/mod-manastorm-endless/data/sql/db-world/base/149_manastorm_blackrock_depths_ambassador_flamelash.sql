-- Blackrock Depths / Ambassador Flamelash (native NPC 9156, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   426 = Normal  (difficulty 0), dungeon encounter  242
--   460 = Endgame (difficulty 2), dungeon encounter 2242
-- Historical duplicate routes to retain but disable:
--   427 = alternate Normal; 461 = alternate Endgame
--
-- Exact player-authored arrival teleport (not the boss spawn):
--   2186, X 873.535, Y -231.503, Z -43.7523,
--   orientation 0.175137, map 230,
--   'Manastorm_BlackrockDepths_AmbassadorFlamelash'
--
-- Native boss_ambassador_flamelash.cpp handles the rune visuals
-- (GO entries 170578-170584), Fire Blast, and Burning Spirit
-- summons (NPC 9178) during combat. No external activation gate
-- is present in the checked BRD instance or boss scripts.
-- Preserve all native creature AI and the original summon positions.
--
-- Rerunnable, guarded migration. Preserve Chaotic Link candidates,
-- stacks, depths, weights, rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2186, 873.535, -231.503, -43.7523, 0.175137, 230,
     'Manastorm_BlackrockDepths_AmbassadorFlamelash');

-- Keep exact duplicate original routes in the DB but not selectable.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 230
  AND `objective_creature_entry` = 9156
  AND ((`segment_id` = 427
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 242)
    OR (`segment_id` = 461
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2242));

-- One original segment per difficulty. Add StartingUnlocked (0x1)
-- without replacing any other existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2186,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 426
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 242
     AND `objective_creature_entry` = 9156
     AND `start_game_tele_id` IN (0, 2186))
 OR (`segment_id` = 460
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2242
     AND `objective_creature_entry` = 9156
     AND `start_game_tele_id` IN (0, 2186));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9156
-- ORDER BY difficulty, segment_id;
