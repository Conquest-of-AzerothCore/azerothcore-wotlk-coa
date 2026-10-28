-- Maraudon / Meshlok the Harvester (native rare NPC 12237, map 349).
--
-- Exact original recovered Ascension Manastorm segments:
--   684 = Normal  (difficulty 0), dungeon encounter 9997
--   683 = Endgame (difficulty 2), dungeon encounter 2621
-- Encounter 9997 is the original Normal identity: do not replace it.
-- There are no alternate recovered Meshlok routes to disable.
--
-- Exact player-authored arrival teleport (not a boss-spawn position):
--   game_tele 2178, X 617.764, Y -136.997, Z -54.7355,
--   orientation 1.19378, map 349,
--   'Manastorm_Maraudon_MeshlokTheHarvester'
--
-- Meshlok is a rare native Maraudon creature. A Manastorm-only,
-- scripted-private C++ bootstrap ensures that the original DB GUID
-- is alive and registered as the objective during PREPARING:
--   - find the genuine DB spawn nearest the player's arrival;
--   - reuse an existing Meshlok in the private instance if present;
--   - otherwise clear only the private respawn time and load his
--     original DB creature at its actual native spawn coordinates.
-- Public Maraudon rare-spawn probability and creature AI are untouched.
--
-- Idempotent and guarded by exact recovered stage identity.
-- Preserve all existing Chaotic Link creature candidates and stacks,
-- stage weights, depth progression, rewards, and unrelated flags.

INSERT IGNORE INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2178, 617.764, -136.997, -54.7355, 1.19378, 349,
     'Manastorm_Maraudon_MeshlokTheHarvester');

-- Enable each exact original Normal/Endgame rare objective,
-- preserve other flags with StartingUnlocked (0x1).
UPDATE `manastorm_segment`
SET
    `start_game_tele_id` = 2178,
    `flags` = (`flags` | 1),
    `enabled` = 1
WHERE
    (`segment_id` = 684
     AND `map_id` = 349
     AND `difficulty` = 0
     AND `dungeon_encounter_id` = 9997
     AND `objective_creature_entry` = 12237
     AND `start_game_tele_id` IN (0, 2178))
 OR (`segment_id` = 683
     AND `map_id` = 349
     AND `difficulty` = 2
     AND `dungeon_encounter_id` = 2621
     AND `objective_creature_entry` = 12237
     AND `start_game_tele_id` IN (0, 2178));

-- Read-only verification after importing:
-- SELECT segment_id, map_id, difficulty, dungeon_encounter_id,
--        objective_creature_entry, start_game_tele_id,
--        chaotic_link_stacks, weight, flags, enabled
-- FROM manastorm_segment
-- WHERE segment_id IN (683, 684)
-- ORDER BY difficulty, segment_id;
