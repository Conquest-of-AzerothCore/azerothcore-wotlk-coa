-- Blackrock Depths / Lord Incendius (native NPC 9017, map 230).
--
-- Recovered original Ascension Manastorm routes:
--   424 = Normal  (difficulty 0), dungeon encounter  232
--   462 = Endgame (difficulty 2), dungeon encounter 2232
-- Duplicate original routes to retain but disable:
--   425 = alternate Normal; 463 = alternate Endgame
--
-- Exact player-authored arrival teleport (not the creature spawn):
--   2185, X 764.262, Y -144.748, Z -73.0507,
--   orientation 5.53941, map 230,
--   'Manastorm_BlackrockDepths_LordIncendius'
--
-- The current BRD instance and general dungeon scripts have no
-- Incendius-specific spawn, summoning, or prerequisite event; there
-- is no dedicated Incendius boss script in the checked directory.
-- Preserve native DB spawn and existing combat behavior.
--
-- Rerunnable, guarded migration. Preserve Chaotic Link candidates
-- and stacks, stage weights/depths, rewards, and unrelated flag bits.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2185, 764.262, -144.748, -73.0507, 5.53941, 230,
     'Manastorm_BlackrockDepths_LordIncendius');

-- Keep alternate original routes in the database but ineligible.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 230
  AND `objective_creature_entry` = 9017
  AND ((`segment_id` = 425
        AND `difficulty` = 0
        AND `dungeon_encounter_id` = 232)
    OR (`segment_id` = 463
        AND `difficulty` = 2
        AND `dungeon_encounter_id` = 2232));

-- Select one original route per difficulty, setting StartingUnlocked
-- (0x1) without clearing any existing flag bits.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2185,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 424
     AND `map_id` = 230
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 232
     AND `objective_creature_entry` = 9017
     AND `start_game_tele_id` IN (0, 2185))
 OR (`segment_id` = 462
     AND `map_id` = 230
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2232
     AND `objective_creature_entry` = 9017
     AND `start_game_tele_id` IN (0, 2185));

-- Read-only post-import verification:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 230 AND objective_creature_entry = 9017
-- ORDER BY difficulty, segment_id;
