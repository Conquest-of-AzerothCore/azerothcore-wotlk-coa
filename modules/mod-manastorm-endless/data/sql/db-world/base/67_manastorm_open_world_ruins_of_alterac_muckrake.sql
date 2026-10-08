-- Restore Ruins of Alterac / Muckrake as a Vanilla open-world
-- Manastorm stage.
--
-- Native identities recovered from Manastorm data:
--   407 = Normal,  map 1761, encounter 4994, objective 83261
--   480 = Endgame, map 1761, encounter 4996, objective 83261
--
-- Ascension used duplicate creature entry 83261. AzerothCore's physical
-- Vanilla Muckrake is creature entry 2421.
--
-- Physical location is the Ruins of Alterac on Eastern Kingdoms map 0.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2108, 623.903, -526.526, 180.286, 1.38229, 0,
     'Manastorm_Openworld_Muckrake')
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
    `runtime_objective_creature_entry` = 2421,
    `start_game_tele_id` = 2108,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (407, 480);
