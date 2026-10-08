-- Shadowfang Keep / Odo the Blindwatcher.
--
-- One Normal and one Endgame segment per boss. Preserve the native catalog
-- and leave the duplicate Normal route disabled.
--
-- Recovered current DB identities:
--   37  = Normal,  map 33, encounter 468,  objective 4279
--   38  = duplicate Normal route (keep disabled)
--   339 = Endgame, map 33, encounter 2468, objective 4279
--
-- User-authored physical start:
--   game_tele 2112, map 33
--   -233.479, 2230.93, 93.5413, orientation 4.84278
--
-- Preserve existing Chaotic Links, weights, and native encounter identity.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2112, -233.479, 2230.93, 93.5413, 4.84278, 33,
     'Manastorm_SFK_OdotheBlindwatcher');

-- Duplicate Normal route remains available for future archaeology only.
UPDATE `manastorm_segment`
SET `enabled` = 0
WHERE `segment_id` = 38
  AND `map_id` = 33
  AND `difficulty` = 0
  AND `dungeon_encounter_id` = 468
  AND `objective_creature_entry` = 4279;

-- Baseline dungeon content: StartingUnlocked bit 0x1.
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2112,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 37
     AND `map_id` = 33
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 468
     AND `objective_creature_entry` = 4279
     AND `start_game_tele_id` IN (0, 2112))
 OR (`segment_id` = 339
     AND `map_id` = 33
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2468
     AND `objective_creature_entry` = 4279
     AND `start_game_tele_id` IN (0, 2112));

-- Verify:
-- SELECT segment_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, flags, enabled
-- FROM manastorm_segment
-- WHERE map_id = 33 AND objective_creature_entry = 4279
-- ORDER BY segment_id;
