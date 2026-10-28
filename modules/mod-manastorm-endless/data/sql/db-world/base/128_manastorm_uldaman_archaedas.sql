-- Uldaman / Archaedas (NPC 2748, map 70).
--
-- Recover exactly one native Manastorm stage for each difficulty:
--   101 = Normal,  dungeon encounter  554
--   385 = Endgame, dungeon encounter 2554
-- No other Archaedas route variants were found in the recovered catalogue.
--
-- Exact player-authored game_tele:
--   2165, X 132.556, Y 285.83, Z -52.2046,
--   orientation 3.57847, map 70,
--   'Manastorm_Uldaman_Archaedas'
--
-- Native Archaedas is a petrified original DB creature. Normally
-- spell_uldaman_boss_agro_archaedas initiates his altar encounter via:
--     instance->SetData(DATA_ARCHAEDAS, IN_PROGRESS)
--     archaedas->AI()->SetData(1, 1)
-- Private Manastorm compatibility in ManastormMgr.cpp registers his
-- native spawn in PREPARING and invokes these exact two operations only
-- after the stage becomes ACTIVE and the protection bubble is removed.
-- Public Uldaman scripts, Stone Keepers, and door behavior are unmodified.
--
-- Rerunnable and scoped to exact recovered identities. Preserve the
-- existing Chaotic Link candidates, stack counts, weights, depths,
-- reward multipliers, other flags, and all independent boss stages.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2165, 132.556, 285.83, -52.2046, 3.57847, 70,
     'Manastorm_Uldaman_Archaedas');

-- StartingUnlocked bit 0x1, preserving all other flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2165,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 101
     AND `map_id` = 70
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 554
     AND `objective_creature_entry` = 2748
     AND `start_game_tele_id` IN (0, 2165))
 OR (`segment_id` = 385
     AND `map_id` = 70
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2554
     AND `objective_creature_entry` = 2748
     AND `start_game_tele_id` IN (0, 2165));

-- Read-only audit after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id, weight,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 70 AND objective_creature_entry = 2748
-- ORDER BY difficulty, segment_id;
