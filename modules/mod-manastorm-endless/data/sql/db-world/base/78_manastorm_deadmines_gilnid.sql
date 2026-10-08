-- Deadmines / Gilnid.
--
-- Restore exactly one Normal and one Endgame Manastorm segment using the
-- user's in-game anchor. Keep other native route variants disabled.
--
-- Recovered Manastorm identities:
--   117 = Normal,  map 36, encounter 163,  objective 1763
--   217 = Endgame, map 36, encounter 2163, objective 1763
--
-- Unused native variants:
--   Normal:  118, 119, 120, 121
--   Endgame: 218, 219, 220, 221
--
-- User-authored starting teleport:
--   game_tele 2118, map 36
--   -208.786, -552.46, 51.2297, orientation 6.07345
--
-- Preserve Chaotic Link candidate selections, stack requirements, weights,
-- encounter identities, and all other existing segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2118, -208.786, -552.46, 51.2297, 6.07345, 36,
     'Manastorm_Deadmines_Gilnid');

-- Do not delete native variants; keep only one route per boss and difficulty.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 36
  AND `objective_creature_entry` = 1763
  AND `segment_id` IN (118, 119, 120, 121, 218, 219, 220, 221);

-- Baseline dungeon content: StartingUnlocked (bit 0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2118,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 117
     AND `map_id` = 36
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 163
     AND `objective_creature_entry` = 1763
     AND `start_game_tele_id` IN (0, 2118))
 OR (`segment_id` = 217
     AND `map_id` = 36
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2163
     AND `objective_creature_entry` = 1763
     AND `start_game_tele_id` IN (0, 2118));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 36 AND objective_creature_entry = 1763
-- ORDER BY segment_id;
