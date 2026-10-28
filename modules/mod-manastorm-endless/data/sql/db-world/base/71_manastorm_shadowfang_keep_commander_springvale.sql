-- Shadowfang Keep / Commander Springvale.
--
-- Author one Normal and one Endgame Manastorm segment per boss.
-- All alternate Springvale route variants remain in the native catalogue,
-- but are disabled instead of assigning them duplicate start positions.
--
-- Recovered native identities:
--   32  = Normal,  map 33, encounter 467,  objective 4278
--   333 = Endgame, map 33, encounter 2467, objective 4278
--
-- User-authored safety-bubble start:
--   game_tele 2111, map 33
--   -304.948, 2283.88, 95.8665, orientation 5.95645
--
-- Preserve Chaotic Links, existing per-segment tuning, and the original
-- map/encounter/objective identities.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2111, -304.948, 2283.88, 95.8665, 5.95645, 33,
     'Manastorm_SFK_CommanderSpringvale');

-- Unused route variants (Normal 33-36; Endgame 334-337).
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 33
  AND `objective_creature_entry` = 4278
  AND `segment_id` IN
      (33, 34, 35, 36, 334, 335, 336, 337);

-- Baseline dungeon content: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2111,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 32
     AND `map_id` = 33
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 467
     AND `objective_creature_entry` = 4278
     AND `start_game_tele_id` IN (0, 2111))
 OR (`segment_id` = 333
     AND `map_id` = 33
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2467
     AND `objective_creature_entry` = 4278
     AND `start_game_tele_id` IN (0, 2111));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 33 AND objective_creature_entry = 4278
-- ORDER BY segment_id;
