-- Blackrock Depths / General Angerforge (native NPC 9033, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   421 = Normal  (difficulty 0), dungeon encounter  236
--   465 = Endgame (difficulty 2), dungeon encounter 2236
-- Duplicate original routes to retain but disable:
--   422 = alternate Normal; 466 = alternate Endgame
--
-- Exact player-authored arrival teleport:
--   2183, X 754.454, Y -77.7925, Z -46.2336,
--   orientation 1.09958, map 230,
--   'Manastorm_BlackrockDepths_GeneralAngerforge'
--
-- Native boss_general_angerforge.cpp handles combat and summons
-- (8901 adds and 8894 medics below 21% health). The BRD instance
-- script does not gate his initial activation behind another event.
-- Preserve his original DB spawn, AI, and reinforcement behavior.
--
-- Rerunnable, guarded migration. Preserve Chaotic Link candidates
-- and stacks, weights, depths, rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2183, 754.454, -77.7925, -46.2336, 1.09958, 230,
     'Manastorm_BlackrockDepths_GeneralAngerforge');

-- Keep alternate original routes in the database but disabled.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 230
  AND `objective_creature_entry` = 9033
  AND ((`segment_id` = 422
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 236)
    OR (`segment_id` = 466
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2236));

-- Select one recovered original route per difficulty, adding
-- StartingUnlocked (0x1) without clearing other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2183,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 421
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 236
     AND `objective_creature_entry` = 9033
     AND `start_game_tele_id` IN (0, 2183))
 OR (`segment_id` = 465
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2236
     AND `objective_creature_entry` = 9033
     AND `start_game_tele_id` IN (0, 2183));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9033
-- ORDER BY difficulty, segment_id;
