-- Blackfathom Deeps / Lady Sarevess.
--
-- Original recovered Manastorm encounter identities (map 48, NPC 4831):
--   Segment  68 = Normal,  encounter  220
--   Segment 235 = Endgame, encounter 2220
-- Unselected historical route variants kept but disabled:
--   69 (Normal), 236 (Endgame).
--
-- Exact user-authored teleport, including name spelling and orientation:
--   2153, X -324.208, Y 290.826, Z -53.0809, O 1.34696, map 48
--   'Manastorm_BlackfathomDeep_LadySarevess'
--
-- Lady Sarevess is not locked behind a special encounter event in
-- the native Blackfathom Deeps instance script. Preserve the original
-- world-DB boss spawn and combat AI. No creature or GO modifications.
-- Preserve manually authored Chaotic Link roster/stack counts, stage
-- depth settings, selection weights, and reward scalars.
-- Safe to reapply without clearing player-authored segment changes.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2153, -324.208, 290.826, -53.0809, 1.34696, 48,
     'Manastorm_BlackfathomDeep_LadySarevess');

-- Only the two alternative original route variants are disabled.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 48
  AND `objective_creature_entry` = 4831
  AND (
      (`segment_id` = 69
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 220)
   OR (`segment_id` = 236
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2220)
  );

-- One original per Normal and Endgame track.
-- OR the StartingUnlocked bit 0x1, preserving other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2153,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 68
     AND `map_id` = 48
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 220
     AND `objective_creature_entry` = 4831
     AND `start_game_tele_id` IN (0, 2153))
 OR (`segment_id` = 235
     AND `map_id` = 48
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2220
     AND `objective_creature_entry` = 4831
     AND `start_game_tele_id` IN (0, 2153));

-- Post-import validation (read-only):
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 48 AND objective_creature_entry = 4831
-- ORDER BY difficulty, segment_id;
