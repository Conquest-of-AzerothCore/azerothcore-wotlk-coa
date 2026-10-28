-- Stratholme / Archivist Galford (native NPC 10811, map 329).
--
-- Recovered original Ascension Manastorm routes:
--   183 = Normal  (difficulty 0), dungeon encounter  477
--   357 = Endgame (difficulty 2), dungeon encounter 2477
-- No historical duplicate Galford routes were recovered.
--
-- Exact player-authored arrival teleport (not a boss-spawn position):
--   2199, X 3538.51, Y -3061.29, Z 135.668,
--   orientation 2.3405, map 329,
--   'Manastorm_Stratholme_ArchivistGalford'
--
-- The native instance_stratholme.cpp and stratholme.h do not define
-- any Archivist Galford-specific summoning or activation event.
-- The Hall of High Command door (GO 176194) belongs to normal
-- instance access/progression. Do not force the door or otherwise
-- change native Stratholme to enable this selected Manastorm boss.
-- Preserve Galford's original DB spawn and native combat behavior.
-- Verify the boss is reachable from the authored arrival and that
-- killing him completes the exact objective in-game.
--
-- Rerunnable and guarded by exact recovered segment identities.
-- Preserve existing Chaotic Link candidates/stacks, weights, depths,
-- rewards, and all pre-existing unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2199, 3538.51, -3061.29, 135.668, 2.3405, 329,
     'Manastorm_Stratholme_ArchivistGalford');

-- Enable one recovered original route per difficulty. Add the
-- StartingUnlocked flag (0x1) without clearing other existing bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2199,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 183
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 477
     AND `objective_creature_entry` = 10811
     AND `start_game_tele_id` IN (0, 2199))
 OR (`segment_id` = 357
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2477
     AND `objective_creature_entry` = 10811
     AND `start_game_tele_id` IN (0, 2199));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10811
-- ORDER BY difficulty, segment_id;
