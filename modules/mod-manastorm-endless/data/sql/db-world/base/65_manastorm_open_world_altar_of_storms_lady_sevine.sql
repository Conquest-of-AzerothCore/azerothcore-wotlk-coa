-- Restore Altar of Storms / Lady Sevine as a Vanilla open-world
-- Manastorm stage.
--
-- Native identities recovered from Manastorm data:
--   554 = Normal,  map 1762, encounter 5045, objective 83619
--   555 = Endgame, map 1762, encounter 5047, objective 83619
--
-- Ascension used duplicate creature entry 83619. AzerothCore's physical
-- Vanilla Lady Sevine is creature entry 7667.
--
-- Physical location is the Blasted Lands / Altar of Storms on
-- Eastern Kingdoms map 0.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2106, -11344, -2555.28, 86.0778, 0.0628442, 0,
     'Manastorm_OpenWorld_LadySevine')
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
    `runtime_objective_creature_entry` = 7667,
    `start_game_tele_id` = 2106,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (554, 555);
