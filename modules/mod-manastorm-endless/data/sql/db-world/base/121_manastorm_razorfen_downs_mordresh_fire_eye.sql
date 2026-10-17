-- Razorfen Downs / Mordresh Fire Eye.
--
-- Recovered original Manastorm segment identities (map 129, NPC 7357):
--    92 = Normal,  dungeon encounter 435
--   295 = Endgame, dungeon encounter 2435
-- Preserve but disable unselected original route variants:
--    93, 94  (Normal) and 296, 297 (Endgame).
--
-- Exact user-authored teleport (preserve all supplied values/name):
--   2159, X 2565, Y 773.091, Z 56.282, orientation 3.98198,
--   map 129, 'Manastorm_RazorfenDowns_MordreshFireEye'
--
-- Mordresh is a normal standing dungeon boss. The native Razorfen Downs
-- instance and encounter scripts do not gate this objective behind the
-- gong or Belnistrasz event. Do not modify boss spawn/AI or event flags.
--
-- Idempotent; no changes to existing Chaotic Link candidates, stacks,
-- selection weight, depth ranges or reward multiplier.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2159, 2565, 773.091, 56.282, 3.98198, 129,
     'Manastorm_RazorfenDowns_MordreshFireEye');

-- Historical alternatives remain in the catalogue but are not selected.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `map_id` = 129
  AND `objective_creature_entry` = 7357
  AND (
      (`segment_id` IN (93, 94)
       AND `difficulty` = 0
       AND `dungeon_encounter_id` = 435)
   OR (`segment_id` IN (296, 297)
       AND `difficulty` = 2
       AND `dungeon_encounter_id` = 2435)
  );

-- Enable only the original selected Normal and Endgame routes.
-- OR StartingUnlocked (bit 0x1), leaving other flag bits untouched.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2159,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 92
     AND `map_id` = 129
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 435
     AND `objective_creature_entry` = 7357
     AND `start_game_tele_id` IN (0, 2159))
 OR (`segment_id` = 295
     AND `map_id` = 129
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2435
     AND `objective_creature_entry` = 7357
     AND `start_game_tele_id` IN (0, 2159));

-- Read-only verification after import:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 129 AND objective_creature_entry = 7357
-- ORDER BY difficulty, segment_id;
