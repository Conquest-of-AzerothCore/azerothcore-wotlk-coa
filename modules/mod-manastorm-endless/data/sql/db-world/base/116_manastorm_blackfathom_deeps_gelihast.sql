-- Blackfathom Deeps / Gelihast.
--
-- Recovered original Manastorm identities (map 48, NPC 6243):
--   70 = Normal,  encounter 221
--  237 = Endgame, encounter 2221
-- Other original route variants, preserved but disabled:
--   71, 72 (Normal) and 238, 239 (Endgame).
--
-- User-authored teleport (including exact spelling/position/orientation):
-- 2154, X -532.399, Y -5.69047, Z -40.4165, O 0.0596605, map 48
-- 'Manastorm_BlackfathhomDeep_Gelihast'
--
-- Gelihast's shrine (GO_SHRINE_OF_GELIHAST) is activated by the
-- native instance's completed-Gelihast state; it is not a prerequisite
-- to locating/killing the boss. Retain native combat/spawn mechanics.
-- No world creature, gameobject, or script modifications are needed.
--
-- This file intentionally does NOT modify any manually authored
-- Chaotic Link candidates, required Link stacks, segment weight,
-- min/max depth, reward multiplier, or other segment flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2154, -532.399, -5.69047, -40.4165, 0.0596605, 48,
     'Manastorm_BlackfathhomDeep_Gelihast');

-- Disable only alternate original Gelihast routes. Keep their rows.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 48
  AND `objective_creature_entry` = 6243
  AND (
      (`segment_id` IN (71, 72)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 221)
   OR (`segment_id` IN (238, 239)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2221)
  );

-- Enable one authentic stage per track; preserve any other flags.
-- STARTING_UNLOCKED flag bit 0x1 permits selecting these bosses
-- without staging other Blackfathom Deeps encounters first.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2154,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 70
     AND `map_id` = 48
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 221
     AND `objective_creature_entry` = 6243
     AND `start_game_tele_id` IN (0, 2154))
 OR (`segment_id` = 237
     AND `map_id` = 48
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2221
     AND `objective_creature_entry` = 6243
     AND `start_game_tele_id` IN (0, 2154));

-- Review all original Gelihast route variants (read-only):
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id, weight,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 48 AND objective_creature_entry = 6243
-- ORDER BY difficulty, segment_id;
