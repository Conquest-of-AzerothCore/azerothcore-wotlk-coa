-- Archmage Arugal (4275) stands at his desk and moves only by Shadow Port. Wrath and Curse of Arugal keep the range and
-- the line-of-sight rule Spell.dbc gives them again (the 30 yards with line of sight from rev_20261113_06 made him walk
-- to players at the lair door). He resets when his target stands outside his lair, on every difficulty.
DELETE FROM `coa_dungeon_spell_reach` WHERE `spell_id` IN (2102677, 2102679);

DELETE FROM `coa_boss_leash` WHERE `entry` = 4275;
INSERT INTO `coa_boss_leash` (`entry`, `radius`, `target`) VALUES (4275, 50, 1) ON DUPLICATE KEY UPDATE `target` = 1;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 4275 AND `source_type` = 0 AND `id` = 9015;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(4275, 0, 9015, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Archmage Arugal - Ascension kit - On Aggro - Disable Combat Movement');
