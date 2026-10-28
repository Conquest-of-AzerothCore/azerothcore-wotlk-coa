-- Uldaman / Revelosh (native NPC 6910, map 70).
--
-- Original recovered Ascension Manastorm encounter identities:
--   593 = Normal  (difficulty 0), dungeon encounter  547
--   592 = Endgame (difficulty 2), dungeon encounter 2547
--
-- Only one historical route per difficulty exists for Revelosh.
-- No invented segments, encounter IDs, alternate routes or summons.
--
-- Exact user-authored teleport: preserve case and the user-entered
-- spelling Ravelosh rather than silently changing its name:
--   game_tele 2168, map 70
--   X -227.143, Y 50.8895, Z -46.0383, orientation 1.58812
--   'Manastorm_Uldaman_Ravelosh'
--
-- Native instance_uldaman.cpp does not contain any special encounter
-- activation sequence for NPC 6910. Use his original spawned creature
-- and combat AI, without modifying the public dungeon.
--
-- Idempotent, narrowly scoped to the original two records. Preserve
-- existing Chaotic Link candidates/stack counts, weight, depths,
-- rewards, other flags, and all unrelated dungeon encounters.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2168, -227.143, 50.8895, -46.0383, 1.58812, 70,
     'Manastorm_Uldaman_Ravelosh');

-- Keep the original per-difficulty segment identities. Only mark
-- them StartingUnlocked, point them at the new teleport, and enable.
-- OR the StartingUnlocked bit (0x1); do not replace other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2168,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 593
     AND `map_id` = 70
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 547
     AND `objective_creature_entry` = 6910
     AND `start_game_tele_id` IN (0, 2168))
 OR (`segment_id` = 592
     AND `map_id` = 70
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2547
     AND `objective_creature_entry` = 6910
     AND `start_game_tele_id` IN (0, 2168));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        weight, chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (592, 593)
-- ORDER BY difficulty, segment_id;
