-- Restore Moonbrook / Marisa du'Paige as a Vanilla open-world Manastorm.
--
-- Native identities remain exactly as recovered from Manastorm.dbc:
--   526 = Normal, map 1769, encounter 5018, objective 84270
--   527 = Endgame, map 1769, encounter 5020, objective 84270
--
-- Ascension used duplicate creature entry 84270. AzerothCore's physical
-- Vanilla Marisa du'Paige is creature entry 599, so use the existing runtime
-- objective override without changing the native identity.
--
-- Physical location is Moonbrook on Eastern Kingdoms map 0.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2103, -11242.1, 1473.88, 24.041, 2.57614, 0,
     'Manastorm_OpenWorld_Marisadu''Paige')
ON DUPLICATE KEY UPDATE
    `position_x` = VALUES(`position_x`),
    `position_y` = VALUES(`position_y`),
    `position_z` = VALUES(`position_z`),
    `orientation` = VALUES(`orientation`),
    `map` = VALUES(`map`),
    `name` = VALUES(`name`);

UPDATE `manastorm_segment`
SET
    `runtime_map_id` = 0,
    `runtime_map_override_enabled` = 1,
    `runtime_objective_creature_entry` = 599,
    `start_game_tele_id` = 2103,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (526, 527);
