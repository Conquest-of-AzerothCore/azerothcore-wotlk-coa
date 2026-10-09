-- Razorfen Kraul / Roogug.
--
-- Enable one Normal and one Endgame segment for this recovered native
-- Manastorm objective. Retain the alternative native routes as disabled
-- catalogue records rather than deleting or rewriting their identities.
--
-- Recovered native identities:
--   82  = Normal,  map 47, encounter 438,  objective 6168
--   300 = Endgame, map 47, encounter 2438, objective 6168
--   Disabled alternate variants: 83 (Normal), 301 (Endgame)
--
-- User-authored start teleport:
--   2123, map 47, X 2074.08, Y 1582.03, Z 82.1902,
--   orientation 5.37759
--
-- Preserve any existing manually authored Chaotic Link route candidates,
-- link stack requirements, weights and all other segment tuning.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2123, 2074.08, 1582.03, 82.1902, 5.37759, 47,
     'Manastorm_RazorfenKraul_Roogug');

-- Preserve unused native variants, but keep them out of selection.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 47
  AND `objective_creature_entry` = 6168
  AND `segment_id` IN (83, 301);

-- Baseline dungeon availability: StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2123,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 82
     AND `map_id` = 47
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 438
     AND `objective_creature_entry` = 6168
     AND `start_game_tele_id` IN (0, 2123))
 OR (`segment_id` = 300
     AND `map_id` = 47
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2438
     AND `objective_creature_entry` = 6168
     AND `start_game_tele_id` IN (0, 2123));

-- Verify the selected routes and the intentionally disabled alternatives:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 47 AND objective_creature_entry = 6168
-- ORDER BY segment_id;
