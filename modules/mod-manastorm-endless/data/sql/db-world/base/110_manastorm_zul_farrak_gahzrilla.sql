-- Zul'Farrak / Gahz'rilla (Ghaz'rilla in recovered encounter names).
--
-- Recovered original Manastorm identities (map 209, creature 7273):
--   198 = Normal,  encounter 594
--   392 = Endgame, encounter 2594
--   Unselected historical variants:
--     199, 200, 201 (Normal); 393, 394, 395 (Endgame).
--
-- Gahz'rilla is normally summoned by ringing the Zul'Farrak gong with
-- the Mallet of Zul'Farrak. ManastormMgr.cpp restores the authentic
-- encounter by summoning creature 7273 at the original pool location
-- (1667.54, 1190.57, -2.80444, 0.890118) ONLY in the two isolated
-- private Manastorm stages. Players never need the Mallet. Ordinary
-- dungeon gong, player items, instances, and boss combat AI are unchanged.
--
-- Exact user-authored starting teleport:
--   2149, map 209, X 1706.51, Y 1161.51, Z 8.98762,
--   orientation 2.42067, name Manastorm_ZulFarrak_Ghaz'rilla
--
-- Do not rewrite native encounter IDs, original route candidates,
-- Chaotic Link stacks, weights, progression depths or rewards.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2149, 1706.51, 1161.51, 8.98762, 2.42067, 209,
     'Manastorm_ZulFarrak_Ghaz\'rilla');

-- Preserve disabled original route alternatives in the catalogue.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 209
  AND `objective_creature_entry` = 7273
  AND (
      (`segment_id` IN (199, 200, 201)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 594)
   OR (`segment_id` IN (393, 394, 395)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2594)
  );

-- StartingUnlocked (bit 0x1) for selected Normal/Endgame.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2149,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 198
     AND `map_id` = 209
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 594
     AND `objective_creature_entry` = 7273
     AND `start_game_tele_id` IN (0, 2149))
 OR (`segment_id` = 392
     AND `map_id` = 209
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2594
     AND `objective_creature_entry` = 7273
     AND `start_game_tele_id` IN (0, 2149));

-- Confirm the two selected segments and historical variants:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 209 AND objective_creature_entry = 7273
-- ORDER BY difficulty, segment_id;
