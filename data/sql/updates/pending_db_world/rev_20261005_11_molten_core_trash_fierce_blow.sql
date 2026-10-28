-- Fierce Blow (975011) on the SmartAI Molten Core trash, each on its own random window so the cast cannot be
-- predicted. Event 0 takes (initial min, initial max, repeat min, repeat max). Windows come from the archive combat
-- logs (SPELL_CAST_SUCCESS per creature guid, de-duplicated; see rev_20261005_10 for the method): repeat 6000-10000 ms
-- everywhere (63-100% of each creature's observed repeats inside it; Flame Imp, Firewalker, Lava Reaver and
-- Flameguard have only 7-12 repeats, so the shared window is a default, not a measurement). First cast 6000-10000 ms
-- unless the creature's own distribution clearly leaves it (below 50% inside): interquartile range with 15 or more
-- first casts, observed min-max below that.
--   Firelord          first  8100-12600  (40 first casts, interquartile range)
--   Lava Elemental    first  7500-12400  (41 first casts, interquartile range)
--   Lava Reaver       first  5700-8000   (18 first casts, interquartile range)
--   Flamewaker        first  6700-21100  (8 first casts, min-max)
-- Difficulty variants (1xxxxx-3xxxxx) never reach GetEntry() on a spawn, so only the base entries carry rows.
-- Only the Fierce Blow row is replaced; the creatures' other events stay with the files that own them.

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11658 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11658, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Molten Giant - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11659 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11659, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Molten Destroyer - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11661 AND `source_type` = 0 AND `id` = 3;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11661, 0, 3, 0, 0, 0, 100, 0, 6700, 21100, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Flamewaker - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11664 AND `source_type` = 0 AND `id` = 4;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11664, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Flamewaker Elite - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11665 AND `source_type` = 0 AND `id` = 3;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11665, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Lava Annihilator - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11666 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11666, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Firewalker - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11667 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11667, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Flameguard - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11668 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11668, 0, 2, 0, 0, 0, 100, 0, 8100, 12600, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Firelord - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11669 AND `source_type` = 0 AND `id` = 1;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11669, 0, 1, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Flame Imp - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11673 AND `source_type` = 0 AND `id` = 5;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11673, 0, 5, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Ancient Core Hound - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 12076 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(12076, 0, 2, 0, 0, 0, 100, 0, 7500, 12400, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Lava Elemental - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 12100 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(12100, 0, 2, 0, 0, 0, 100, 0, 5700, 8000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Lava Reaver - In Combat - Cast Fierce Blow');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 12101 AND `source_type` = 0 AND `id` = 1;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(12101, 0, 1, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Lava Surger - In Combat - Cast Fierce Blow');
