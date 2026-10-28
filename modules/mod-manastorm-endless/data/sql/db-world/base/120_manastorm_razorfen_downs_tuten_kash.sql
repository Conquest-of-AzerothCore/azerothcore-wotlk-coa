-- Razorfen Downs / Tuten'kash.
--
-- Original Ascension Manastorm segment records (map 129, NPC 7355):
--   294 = Endgame only, dungeon encounter 2434.
--   No original Normal segment for this boss exists in recovered data.
--
-- In-game player-authored start teleport (preserve exact name/coords):
--   2158, 2514.93, 882.652, 46.4776, 4.87465, map 129
--   'Manastorm_RazorfenDowns_Tuten\'kash'
--
-- Tuten'kash is summoned by Razorfen Downs' native gong (GO 148917),
-- rather than placed as a permanent world DB creature.
-- ManastormMgr.cpp prepares the original boss at the historical
-- 3.3.5 gong summon location only in isolated Endgame segment 294,
-- and locks gong interaction for that instance to avoid duplicate
-- encounter waves. Native Tuten'kash combat AI is preserved.
--
-- Keep the recovered segment identity and existing config. Do not
-- change any manual Chaotic Link roster/stacks, depth/weight/rewards
-- or flags other than StartingUnlocked 0x1. Safe to rerun.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2158, 2514.93, 882.652, 46.4776, 4.87465, 129,
     'Manastorm_RazorfenDowns_Tuten\'kash');

-- Original Endgame record only. Do not fabricate Normal coverage.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2158,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE `segment_id` = 294
  AND `map_id` = 129
  AND `difficulty` = 2
  AND `dungeon_encounter_id` = 2434
  AND `objective_creature_entry` = 7355
  AND `start_game_tele_id` IN (0, 2158);

-- Post-import audit (read-only):
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 129 AND objective_creature_entry = 7355
-- ORDER BY difficulty, segment_id;
