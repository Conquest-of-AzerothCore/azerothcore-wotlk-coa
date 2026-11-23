CREATE TABLE IF NOT EXISTS `coa_dungeon_spell_radius` (
    `spell_id` INT UNSIGNED NOT NULL,
    `radius_index` INT UNSIGNED NOT NULL,
    `comment` VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_dungeon_spell_radius` WHERE `spell_id` = 2102555;
INSERT INTO `coa_dungeon_spell_radius` (`spell_id`, `radius_index`, `comment`) VALUES
    (2102555, 26, 'Dextren Ward: Bladestorm whirlwind hits the 4 yd circle its visual shows (DBC 2 yd)');

UPDATE `smart_scripts` SET `link` = 9004
WHERE `entryorguid` = 1663 AND `source_type` = 0 AND `id` = 9001 AND `action_type` = 11 AND `action_param1` = 2102554;

UPDATE `smart_scripts` SET `event_type` = 59, `event_param1` = 1, `event_param2` = 0, `event_param3` = 0, `event_param4` = 0,
    `comment` = 'Dextren Ward - Ascension kit - On Timed Event 1 (after Bladestorm) - Cast ''Bellowing Roar'''
WHERE `entryorguid` = 1663 AND `source_type` = 0 AND `id` = 9002 AND `action_type` = 11 AND `action_param1` = 2102761;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1663 AND `source_type` = 0 AND `id` = 9004;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (1663, 0, 9004, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 6500, 6500, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dextren Ward - Ascension kit - Linked to Bladestorm - Roar once it ends (6.5 s)');
