-- Deadmines / Rhahk'Zor.
--
-- Restore one Normal and one Endgame Manastorm segment using the
-- user-authored start position. Keep extra native route variants disabled.
--
-- Recovered Manastorm identities:
--   111 = Normal,  map 36, encounter 161,  objective 644
--   211 = Endgame, map 36, encounter 2161, objective 644
--   Disabled alternatives: 112 (Normal), 212 (Endgame)
--
-- User-authored game_tele 2116:
--   map 36, -115.762, -445.285, 55.0178, orientation 1.8292
--
-- Preserve native encounter identities, manually authored Chaotic Links,
-- existing stack counts, weights, and all other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2116, -115.762, -445.285, 55.0178, 1.8292, 36,
     'Manastorm_Deadmines_Rhahk''Zor');

-- Retain recovered variants without allowing duplicate Rhahk'Zor routes.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 644
  AND `segment_id` IN (112, 212);

-- Baseline dungeon content: StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2116,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 111
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 161
     AND `objective_creature_entry` = 644
     AND `start_game_tele_id` IN (0, 2116))
 OR (`segment_id` = 211
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2161
     AND `objective_creature_entry` = 644
     AND `start_game_tele_id` IN (0, 2116));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 36 AND objective_creature_entry = 644
-- ORDER BY segment_id;
