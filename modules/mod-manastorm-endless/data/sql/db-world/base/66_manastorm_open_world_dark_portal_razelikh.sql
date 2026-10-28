-- Restore Dark Portal / Razelikh the Defiler as a Vanilla
-- open-world Manastorm stage.
--
-- Native identities recovered from Manastorm data:
--   542 = Normal,  map 1762, encounter 5030, objective 84272
--   543 = Endgame, map 1762, encounter 5032, objective 84272
--
-- Ascension used duplicate creature entry 84272. AzerothCore's physical
-- Vanilla Razelikh the Defiler is creature entry 7664.
--
-- Razelikh has no persistent creature spawn row in the Vanilla world DB;
-- he is quest-summoned on the Rise of the Defiler. ManastormMgr therefore
-- bootstraps a temporary 7664 at his native home point for these exact
-- disposable stages.
--
-- Physical location is the Blasted Lands on Eastern Kingdoms map 0.

INSERT INTO `game_tele`
    (`id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `map`, `name`)
VALUES
    (2107, -11239.7, -2849.75, 157.972, 1.33518, 0,
     'Manastorm_OpenWorld_Razelikh')
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
    `runtime_objective_creature_entry` = 7664,
    `start_game_tele_id` = 2107,
    `flags` = (`flags` & ~1),
    `enabled` = 1
WHERE `segment_id` IN (542, 543);
