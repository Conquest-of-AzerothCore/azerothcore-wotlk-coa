-- Restore The Tainted Scar: Part II / Archmage Allistarj as a
-- Vanilla open-world Manastorm stage.
--
-- Native identities recovered from Manastorm.dbc:
--   552 = Normal,  map 1762, encounter 5036, objective 83618
--   553 = Endgame, map 1762, encounter 5038, objective 83618
--
-- Ascension used duplicate creature entry 83618. AzerothCore's physical
-- Vanilla Archmage Allistarj is creature entry 7666.
--
-- Physical location is the Blasted Lands / Tainted Scar on
-- Eastern Kingdoms map 0.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2105, -11256.5, -3525.49, 9.11273, 0.0950164, 0,
     'Manastorm_Openworld_ArchmageAllistarj')
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
    `runtime_objective_creature_entry` = 7666,
    `start_game_tele_id` = 2105,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (552, 553);
