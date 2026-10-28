-- Stratholme / Balnazzar (objective NPC 10813, map 329).
--
-- Original recovered Ascension Manastorm routes:
--   187 = Normal  (difficulty 0), dungeon encounter  478
--   358 = Endgame (difficulty 2), dungeon encounter 2478
-- No historical duplicate Balnazzar routes were recovered.
--
-- Exact player-authored arrival teleport (NOT a boss spawn):
--   2200, X 3540.59, Y -3066.15, Z 135.668,
--   orientation 2.1261, map 329,
--   'Manastorm_Stratholme_Balnazzar'
--
-- IMPORTANT: Balnazzar (10813) is not a separate world DB spawn in
-- the original Scarlet-side encounter. Grand Crusader Dathrohan
-- (10812) is the persistent native spawn, transformed into Balnazzar
-- (10813) below 40% health by SmartAI action 36 (update template).
-- Both forms retain the SAME runtime creature GUID.
--
-- Private-stage-only handling was implemented in ManastormMgr.cpp:
-- OnCreatureAddWorld registers that original Dathrohan GUID for
-- exactly original segments 187 and 358 when 10813 is the objective.
-- OnUnitDeath still requires the final Balnazzar entry 10813.
-- Do NOT create a permanent 10813 spawn, bypass transformation,
-- or change the native SmartAI/event flow.
--
-- Verify that players can reach native Dathrohan from this arrival.
-- The authored teleport is near Galford's 2199 teleport; do not
-- change it without player authorization.
--
-- Rerunnable guarded migration. Preserve original Chaotic Link
-- candidates/stacks, weights, depths, rewards and unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2200, 3540.59, -3066.15, 135.668, 2.1261, 329,
     'Manastorm_Stratholme_Balnazzar');

-- Exactly one original route per difficulty. Add StartingUnlocked
-- (0x1), retaining all other pre-existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2200,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 187
     AND `map_id` = 329
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 478
     AND `objective_creature_entry` = 10813
     AND `start_game_tele_id` IN (0, 2200))
 OR (`segment_id` = 358
     AND `map_id` = 329
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2478
     AND `objective_creature_entry` = 10813
     AND `start_game_tele_id` IN (0, 2200));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 329 AND objective_creature_entry = 10813
-- ORDER BY difficulty, segment_id;
