-- Razorfen Downs / Plaguemaw the Rotting.
--
-- Recovered original Ascension Manastorm segment:
--    689 = Endgame only, map 129, encounter 2618, NPC 7356.
--    No original Normal stage for Plaguemaw was recovered.
--
-- Preserve exact player-authored game_tele:
--    2162, X 2587.77, Y 1085.95, Z 53.0578,
--    orientation 5.09262, map 129,
--    'Manastorm_RazorfenDowns_PlaguemawtheRotting'
--
-- The native boss is spawned by npc_idol_room_spawner (8611) on
-- Belnistrasz's final escort wave, not by a persistent creature row.
-- The stage-specific private instance bootstrap in ManastormMgr.cpp
-- summons original NPC 7356 at an exact native event spawner position
-- (2582.789, 954.3925, 52.48214, orientation 3.787364), without
-- running the public escort or summoning extra trash/duplicates.
--
-- Idempotent migration: no Chaotic Link roster/stacks changes, no
-- changes to other RFD segments, no global creature/escort edits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2162, 2587.77, 1085.95, 53.0578, 5.09262, 129,
     'Manastorm_RazorfenDowns_PlaguemawtheRotting');

-- Enable only the historically recovered Endgame stage 689.
-- Set StartingUnlocked bit 0x1, preserving every other flag bit.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2162,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE `segment_id` = 689
  AND `map_id` = 129
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2618
  AND `objective_creature_entry` = 7356
  AND `start_game_tele_id` IN (0, 2162);

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 129 AND objective_creature_entry = 7356
-- ORDER BY difficulty, segment_id;
