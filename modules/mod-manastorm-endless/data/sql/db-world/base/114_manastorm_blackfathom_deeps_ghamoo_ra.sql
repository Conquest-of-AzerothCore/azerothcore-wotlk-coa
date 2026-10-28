-- Blackfathom Deeps / Ghamoo-ra.
--
-- Recovered original Manastorm encounter identity (map 48, NPC 4887):
--   Segment  63 = Normal,  encounter  219
--   Segment 231 = Endgame, encounter 2219
-- Preserve but disable unselected native route variants:
--   Normal: 64, 65, 66, 67
--   Endgame: 232, 233, 234
--
-- Exact player-authored game_tele (including spelling and orientation):
--   2152, X -376.658, Y 147.198, Z -53.2939, O 2.37819,
--   map 48, 'Manastorm_BlackfathomDeep_GhamooRa'.
--
-- The native BFD instance script reserves event-gated mechanics for
-- later encounters (not Ghamoo-ra). Reuse the original boss DB spawn
-- and native AI. Do not summon a replacement, manipulate doors, or
-- globally edit world creatures or gameobjects.
--
-- This migration is rerunnable and preserves manually authored Chaotic
-- Link candidates, required stacks, weight, depths, reward and flags
-- outside the StartingUnlocked bit.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2152, -376.658, 147.198, -53.2939, 2.37819, 48,
     'Manastorm_BlackfathomDeep_GhamooRa');

-- Historical alternatives remain in the database but will not be
-- randomly selected; guard by their exact original encounter identity.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 48
  AND `objective_creature_entry` = 4887
  AND (
      (`segment_id` IN (64, 65, 66, 67)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 219)
   OR (`segment_id` IN (232, 233, 234)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2219)
  );

-- Exactly one chosen original per track. Preserve any manually
-- configured flags; OR in StartingUnlocked (0x1) only.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2152,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 63
     AND `map_id` = 48
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 219
     AND `objective_creature_entry` = 4887
     AND `start_game_tele_id` IN (0, 2152))
 OR (`segment_id` = 231
     AND `map_id` = 48
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2219
     AND `objective_creature_entry` = 4887
     AND `start_game_tele_id` IN (0, 2152));

-- Post-import review (read-only):
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 48 AND objective_creature_entry = 4887
-- ORDER BY difficulty, segment_id;
