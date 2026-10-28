-- Restore Lost Rigger Cove / Andre Firebeard as a Vanilla
-- open-world Manastorm stage.
--
-- Native identities recovered from Manastorm data:
--   413 = Normal,  map 1767, encounter 5015, objective 83668
--   474 = Endgame, map 1767, encounter 5017, objective 83668
--
-- Ascension used duplicate creature entry 83668. AzerothCore's physical
-- Vanilla Andre Firebeard is creature entry 7883.
--
-- Physical location is Lost Rigger Cove, Tanaris on Kalimdor map 1.
--
-- The imported catalog also contains later duplicate Andre rows
-- (652 / 653 / 655). Those remain untouched/disabled; this restoration uses
-- the original paired Normal/Endgame rows 413 / 474.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2109, -7978.74, -5451.69, 13.094, 0.84035, 1,
     'Manastorm_OpenWorld_AndreFirebeard')
ON DUPLICATE KEY UPDATE
    `position_x` = VALUES(`position_x`),
    `position_y` = VALUES(`position_y`),
    `position_z` = VALUES(`position_z`),
    `orientation` = VALUES(`orientation`),
    `map` = VALUES(`map`),
    `name` = VALUES(`name`);

UPDATE `manastorm_segment`
SET
    `runtime_map_id` = 1,
    `runtime_map_override_enabled` = 1,
    `runtime_objective_creature_entry` = 7883,
    `start_game_tele_id` = 2109,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (413, 474);
