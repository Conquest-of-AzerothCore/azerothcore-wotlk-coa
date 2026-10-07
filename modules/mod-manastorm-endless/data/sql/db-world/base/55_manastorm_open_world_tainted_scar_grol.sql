-- Restore The Tainted Scar: Part I / Grol the Destroyer as a
-- Vanilla open-world Manastorm stage.
--
-- Native identities recovered from Manastorm.dbc:
--   409 = Normal,  map 1762, encounter 5000, objective 83617
--   478 = Endgame, map 1762, encounter 5002, objective 83617
--
-- Ascension used duplicate creature entry 83617. AzerothCore's physical
-- Vanilla Grol the Destroyer is creature entry 7665.
--
-- Physical location is the Blasted Lands / Tainted Scar on
-- Eastern Kingdoms map 0.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2104, -10926.2, -2722.45, 7.63578, 0.72179, 0,
     'Manastorm_OpenWorld_GroltheDestroyer')
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
    `runtime_objective_creature_entry` = 7665,
    `start_game_tele_id` = 2104,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (409, 478);
