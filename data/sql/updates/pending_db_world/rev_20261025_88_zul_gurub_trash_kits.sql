-- Zul'Gurub trash kits from the live combat logs in the db.ascension.gg archive (C:\CoA\SUB\old-logs):
-- the CoA spell ids replace their vanilla counterparts, the abilities the logs add are cast on the
-- victim, and Fierce Blow (975011) and Berserking (1126297) go on every entry the logs show casting them.
-- The logs carry no timings, so the windows are the Molten Core defaults (rev_20261005_11): Fierce Blow
-- 6000-10000 ms first and repeat, other abilities 5000-10000 first and 10000-15000 repeat, Ravage after
-- its 20 s category cooldown, Berserking once per its 3-minute cooldown. Poisonous Fangs is a permanent
-- proc aura and goes on at reset. Difficulty variants never reach GetEntry() on a spawn, so only the
-- base entries carry rows. The Gurubashi Bat Rider (14750) is a C++ script and is left out here.

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (11361, 11387, 14880, 15068);

UPDATE `smart_scripts` SET `action_param1` = 350383
 WHERE `entryorguid` = 11338 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 15232;
UPDATE `smart_scripts` SET `action_param1` = 350386
 WHERE `entryorguid` = 11338 AND `source_type` = 0 AND `id` = 2 AND `action_param1` = 20741;
UPDATE `smart_scripts` SET `action_param1` = 2118900, `comment` = REPLACE(`comment`, '\'Throw\'', '\'Axe Throw\'')
 WHERE `entryorguid` = 11350 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 22887;
UPDATE `smart_scripts` SET `action_param1` = 340021
 WHERE `entryorguid` = 11350 AND `source_type` = 0 AND `id` = 2 AND `action_param1` = 8269;
UPDATE `smart_scripts` SET `action_param1` = 2118905
 WHERE `entryorguid` = 11350 AND `source_type` = 0 AND `id` = 4 AND `action_param1` = 24018;
UPDATE `smart_scripts` SET `action_param1` = 340009
 WHERE `entryorguid` = 11351 AND `source_type` = 0 AND `id` = 3 AND `action_param1` = 15708;
UPDATE `smart_scripts` SET `action_param1` = 340164
 WHERE `entryorguid` = 11352 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 11130;
UPDATE `smart_scripts` SET `action_param1` = 340080
 WHERE `entryorguid` = 11352 AND `source_type` = 0 AND `id` = 2 AND `action_param1` = 15588;
UPDATE `smart_scripts` SET `action_param1` = 340021
 WHERE `entryorguid` = 11352 AND `source_type` = 0 AND `id` = 3 AND `action_param1` = 8269;
UPDATE `smart_scripts` SET `action_param1` = 340021
 WHERE `entryorguid` = 11359 AND `source_type` = 0 AND `id` = 2 AND `action_param1` = 8269;
UPDATE `smart_scripts` SET `action_param1` = 85309, `comment` = REPLACE(`comment`, '\'Heal\'', '\'Greater Heal\'')
 WHERE `entryorguid` = 11830 AND `source_type` = 0 AND `id` = 4 AND `action_param1` = 22883;
UPDATE `smart_scripts` SET `action_param1` = 350048
 WHERE `entryorguid` = 14821 AND `source_type` = 0 AND `id` = 0 AND `action_param1` = 24339;
UPDATE `smart_scripts` SET `action_param1` = 340031
 WHERE `entryorguid` = 14821 AND `source_type` = 0 AND `id` = 2 AND `action_param1` = 8599;
UPDATE `smart_scripts` SET `action_param1` = 340516
 WHERE `entryorguid` = 15043 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 13445;
UPDATE `smart_scripts` SET `action_param1` = 350395
 WHERE `entryorguid` = 15111 AND `source_type` = 0 AND `id` = 0 AND `action_param1` = 24611;
UPDATE `smart_scripts` SET `action_param1` = 350399
 WHERE `entryorguid` = 15111 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 24612;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11338 AND `source_type` = 0 AND `id` IN (3, 4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11338, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Shadowcaster - In Combat - Cast \'Fierce Blow\''),
(11338, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Shadowcaster - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11339 AND `source_type` = 0 AND `id` IN (5, 6);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11339, 0, 5, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Shadow Hunter - In Combat - Cast \'Fierce Blow\''),
(11339, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Shadow Hunter - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11340 AND `source_type` = 0 AND `id` IN (3, 4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11340, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Blood Priest - In Combat - Cast \'Fierce Blow\''),
(11340, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Blood Priest - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11350 AND `source_type` = 0 AND `id` IN (5, 6, 7);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11350, 0, 5, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    2118901, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Axe Thrower - In Combat - Cast \'Deep Wound\''),
(11350, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Axe Thrower - In Combat - Cast \'Fierce Blow\''),
(11350, 0, 7, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Axe Thrower - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11351 AND `source_type` = 0 AND `id` IN (4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11351, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Headhunter - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11352 AND `source_type` = 0 AND `id` IN (5, 6);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11352, 0, 5, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    2118910, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Berserker - In Combat - Cast \'Trauma\''),
(11352, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Berserker - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11353 AND `source_type` = 0 AND `id` IN (2, 3);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11353, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Blood Drinker - In Combat - Cast \'Fierce Blow\''),
(11353, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Blood Drinker - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11356 AND `source_type` = 0 AND `id` IN (5, 6);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11356, 0, 5, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Champion - In Combat - Cast \'Fierce Blow\''),
(11356, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Gurubashi Champion - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11357 AND `source_type` = 0 AND `id` IN (3, 4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11357, 0, 3, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    2118675, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Son of Hakkar - In Combat - Cast \'Pool of Poisoned Blood\''),
(11357, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Son of Hakkar - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11359 AND `source_type` = 0 AND `id` IN (4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11359, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Soulflayer - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11361 AND `source_type` = 0 AND `id` IN (0, 1, 2);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11361, 0, 0, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    24332, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Tiger - In Combat - Cast \'Rake\''),
(11361, 0, 1, 0, 0, 0, 100, 0, 8000, 12000, 20000, 25000, 0, 0, 11,
    24333, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Tiger - In Combat - Cast \'Ravage\''),
(11361, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Tiger - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11368 AND `source_type` = 0 AND `id` IN (1, 2, 3);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11368, 0, 1, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    2106151, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Bloodseeker Bat - In Combat - Cast \'Vampiric Bite\''),
(11368, 0, 2, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    2106156, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Bloodseeker Bat - In Combat - Cast \'Frenzied Dive\''),
(11368, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Bloodseeker Bat - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11370 AND `source_type` = 0 AND `id` IN (2);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11370, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Broodwidow - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11371 AND `source_type` = 0 AND `id` IN (3);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11371, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Serpent - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11372 AND `source_type` = 0 AND `id` IN (3);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11372, 0, 3, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Adder - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11373 AND `source_type` = 0 AND `id` IN (0, 1);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11373, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11,
    2118075, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Cobra - On Reset - Cast \'Poisonous Fangs\''),
(11373, 0, 1, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Cobra - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11374 AND `source_type` = 0 AND `id` IN (1);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11374, 0, 1, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hooktooth Frenzy - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11387 AND `source_type` = 0 AND `id` IN (0);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11387, 0, 0, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Sandfury Speaker - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11830 AND `source_type` = 0 AND `id` IN (5, 6);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11830, 0, 5, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Priest - In Combat - Cast \'Fierce Blow\''),
(11830, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Priest - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11831 AND `source_type` = 0 AND `id` IN (5, 6);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(11831, 0, 5, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Witch Doctor - In Combat - Cast \'Fierce Blow\''),
(11831, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 180000, 180000, 0, 0, 11,
    1126297, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Hakkari Witch Doctor - In Combat - Cast \'Berserking\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 14532 AND `source_type` = 0 AND `id` IN (1, 2);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(14532, 0, 1, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    2118914, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Venombrood - In Combat - Cast \'Poison Volley\''),
(14532, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Venombrood - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 14821 AND `source_type` = 0 AND `id` IN (4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(14821, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Raptor - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 14880 AND `source_type` = 0 AND `id` IN (0);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(14880, 0, 0, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Razzashi Skitterer - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 14884 AND `source_type` = 0 AND `id` IN (4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(14884, 0, 4, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11,
    2118075, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Parasitic Serpent - On Reset - Cast \'Poisonous Fangs\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 15043 AND `source_type` = 0 AND `id` IN (6);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(15043, 0, 6, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Crocolisk - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 15068 AND `source_type` = 0 AND `id` IN (0, 1, 2);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(15068, 0, 0, 0, 0, 0, 100, 0, 5000, 10000, 10000, 15000, 0, 0, 11,
    24332, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Guardian - In Combat - Cast \'Rake\''),
(15068, 0, 1, 0, 0, 0, 100, 0, 8000, 12000, 20000, 25000, 0, 0, 11,
    24333, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Guardian - In Combat - Cast \'Ravage\''),
(15068, 0, 2, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Zulian Guardian - In Combat - Cast \'Fierce Blow\'');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 15111 AND `source_type` = 0 AND `id` IN (4);
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(15111, 0, 4, 0, 0, 0, 100, 0, 6000, 10000, 6000, 10000, 0, 0, 11,
    975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
    'Mad Servant - In Combat - Cast \'Fierce Blow\'');
