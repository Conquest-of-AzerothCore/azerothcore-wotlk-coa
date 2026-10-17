-- Maraudon / Celebras the Cursed (native NPC 12225, map 349).
--
-- Original recovered Ascension Manastorm stage identities:
--   435 = Normal  (difficulty 0), dungeon encounter  425
--   452 = Endgame (difficulty 2), dungeon encounter 2425
-- These are the only two historical Celebras the Cursed routes:
-- one per difficulty. Do not invent alternate segments or IDs.
--
-- Exact player-authored start teleport:
--   game_tele 2174, X 870.316, Y -181.891, Z -86.8024,
--   orientation 1.97841, map 349,
--   name 'Manastorm_Maraudon_CelebrastheCursed'
--
-- The native Maraudon instance script contains no Celebras activation
-- prerequisite; its only documented stage-event handling is the
-- Noxxion Corruption Spewer. Keep the original NPC 12225 spawn and AI.
-- Any post-fight redeemed Celebras quest mechanics are not a
-- prerequisite for this native boss-kill objective.
--
-- Idempotent and narrowly scoped. Preserve all user-configured
-- Chaotic Link candidate rosters and stacks, weights, depth limits,
-- reward multipliers, unrelated flags and other dungeon stages.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2174, 870.316, -181.891, -86.8024, 1.97841, 349,
     'Manastorm_Maraudon_CelebrastheCursed');

-- Enable one original route per difficulty. Preserve other flag bits
-- by OR-ing only StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2174,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 435
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 425
     AND `objective_creature_entry` = 12225
     AND `start_game_tele_id` IN (0, 2174))
 OR (`segment_id` = 452
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2425
     AND `objective_creature_entry` = 12225
     AND `start_game_tele_id` IN (0, 2174));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        weight, chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (435, 452)
-- ORDER BY difficulty, segment_id;
