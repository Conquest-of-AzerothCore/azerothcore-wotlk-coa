-- Bosses whose Ascension kit main already implemented (Deadmines #6282, Upper Blackrock Spire #6175) fight with
-- main's kit: the vanilla dungeon kit rows from id 9000 are removed and main's rows restored. Jed Runewatcher and
-- Goraluk Anvilcrack run main's rows on every difficulty, as do the Chromatic Elite Guards (10814); Jed's despawn
-- stays Normal only. Jed's Fierce Blow uses the interval from the Ascension combat logs (7.7-9.7 s, then 8-9 s).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 639 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(639, 0, 0, 0, 1, 0, 100, 257, 1000, 1000, 0, 0, 0, 0, 11, 674, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Out of Combat - Cast ''Dual Wield'' (No Repeat)'),
(639, 0, 1, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - On Aggro - Say Line 0'),
(639, 0, 3, 9, 2, 0, 100, 1, 34, 66, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 34-66% Health - Say Line 1 (No Repeat)'),
(639, 0, 4, 5, 2, 0, 100, 1, 0, 50, 0, 0, 0, 0, 11, 5200, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 0-50% Health - Cast ''VanCleef`s Allies'' (No Repeat)'),
(639, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 0-50% Health - Say Line 2 (No Repeat)'),
(639, 0, 6, 12, 2, 0, 100, 1, 0, 33, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 0-33% Health - Say Line 3 (No Repeat)'),
(639, 0, 7, 0, 5, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - On Killed Unit - Say Line 4'),
(639, 0, 8, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - On Just Died - Say Line 5'),
(639, 0, 9, 10, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 34-66% Health - Summon Buster Call Marker'),
(639, 0, 10, 11, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 34-66% Health - Summon Buster Call Marker'),
(639, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 34-66% Health - Summon Buster Call Marker'),
(639, 0, 12, 13, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 0-33% Health - Summon Buster Call Marker'),
(639, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 0-33% Health - Summon Buster Call Marker'),
(639, 0, 14, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 180238, 3, 10000, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Edwin VanCleef - Between 0-33% Health - Summon Buster Call Marker');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 642 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(642, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 5141, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed''s Shredder - On Just Died - Cast Eject Sneed'),
(642, 0, 1, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed''s Shredder - In Combat - Cast Fierce Blow'),
(642, 0, 2, 0, 0, 0, 100, 0, 12000, 15000, 20000, 25000, 0, 0, 11, 2102559, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed''s Shredder - In Combat - Cast Bouncing Saw Blade'),
(642, 0, 3, 0, 0, 0, 100, 0, 5000, 8000, 15000, 20000, 0, 0, 11, 2102569, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed''s Shredder - In Combat - Cast Throw Buzzing Saw Blade');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 643 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(643, 0, 0, 0, 0, 0, 100, 0, 1000, 7000, 20000, 25000, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed - In Combat - Cast Disarm'),
(643, 0, 1, 0, 6, 0, 100, 512, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 14, 26185, 16400, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed - Open Door on Death'),
(643, 0, 2, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Sneed - In Combat - Cast Fierce Blow');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 644 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(644, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Rhahk''Zor - On Aggro - Say Line 0'),
(644, 0, 2, 3, 6, 0, 100, 512, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 14, 30533, 13965, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Rhahk''Zor - On Just Died - Activate Gameobject'),
(644, 0, 3, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 34, 0, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Rhahk''Zor - On Just Died - Set Instance Data 0 to 3'),
(644, 0, 4, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Rhahk''Zor - In Combat - Cast Fierce Blow'),
(644, 0, 5, 0, 0, 0, 100, 0, 12000, 16000, 15000, 20000, 0, 0, 11, 2102553, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Rhahk''Zor - In Combat - Cast Stunning Strike'),
(644, 0, 6, 0, 0, 0, 100, 0, 8000, 10000, 15000, 20000, 0, 0, 11, 2102554, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Rhahk''Zor - In Combat - Cast Bladestorm');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 645 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(645, 0, 1, 0, 0, 2, 100, 0, 20000, 25000, 30000, 40000, 0, 0, 11, 2102590, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - In Combat - Cast Cookie''s Cooking'),
(645, 0, 2, 3, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - On Aggro - Stop Combat Movement'),
(645, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 97, 30, 8, 0, 0, 0, 0, 1, 0, 0, 0, 0, -69.131, -852.869, 17.6346, 4.65475, 'Cookie - On Aggro - Jump Into Cauldron'),
(645, 0, 4, 5, 34, 0, 100, 0, 16, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - Landed In Cauldron - Set Phase 2'),
(645, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 103, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - Landed In Cauldron - Root'),
(645, 0, 6, 7, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - On Evade - Set Phase 0'),
(645, 0, 7, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 21, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - On Evade - Allow Combat Movement'),
(645, 0, 8, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 103, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - On Evade - Unroot'),
(645, 0, 9, 0, 0, 2, 100, 0, 1500, 2500, 1600, 1700, 0, 0, 11, 2102589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - In Cauldron - Cast Throw Food'),
(645, 0, 10, 0, 0, 2, 100, 0, 8000, 12000, 12000, 18000, 0, 0, 11, 2102527, 1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Cookie - In Cauldron - Cast Throw Poison Vial');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 647 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(647, 0, 0, 0, 0, 0, 100, 0, 1000, 7000, 10000, 15000, 0, 0, 11, 40505, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Captain Greenskin - In Combat - Cast Cleave'),
(647, 0, 1, 0, 0, 0, 100, 0, 10000, 12000, 25000, 35000, 0, 0, 11, 5208, 0, 0, 0, 0, 0, 5, 10, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Captain Greenskin - In Combat - Cast Poisoned Harpoon'),
(647, 0, 2, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Captain Greenskin - In Combat - Cast Fierce Blow'),
(647, 0, 3, 0, 0, 0, 100, 0, 15000, 20000, 20000, 25000, 0, 0, 11, 2101111, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Captain Greenskin - In Combat - Cast Frost Nova');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1763 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(1763, 0, 0, 0, 0, 0, 100, 0, 1000, 6000, 15000, 25000, 0, 0, 11, 5213, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Gilnid - In Combat - Cast Molten Metal'),
(1763, 0, 1, 0, 1, 0, 100, 0, 120000, 120000, 120000, 120000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Gilnid - Out of Combat - Say Line 0'),
(1763, 0, 2, 0, 6, 0, 100, 512, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 14, 26182, 16399, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Gilnid - On Just Died - Activate Gameobject'),
(1763, 0, 3, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Gilnid - In Combat - Cast Fierce Blow'),
(1763, 0, 4, 0, 0, 0, 100, 0, 10000, 14000, 18000, 24000, 0, 0, 11, 2102571, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Gilnid - In Combat - Cast Melt Ore');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10509 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10509, 0, 0, 0, 37, 0, 85, 514, 0, 0, 0, 0, 0, 0, 41, 500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'On AI initialize - None: Despawn in 0.5 s'),
(10509, 0, 1, 0, 0, 0, 100, 0, 5000, 7000, 4000, 6000, 0, 0, 11, 14516, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Every 4 - 6 seconds (5 - 7s initially)  - Self: Cast spell Strike (14516) on Victim'),
(10509, 0, 2, 0, 105, 0, 100, 0, 10000, 10000, 10000, 10000, 0, 5, 11, 11972, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Every 10 seconds  - Self: Cast spell Shield Bash (11972) on Victim'),
(10509, 0, 3, 0, 0, 0, 100, 0, 10000, 10000, 5000, 15000, 0, 0, 11, 15749, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Every 5 - 15 seconds (10 - 10s initially)  - Self: Cast spell Shield Charge (15749) on Random hostile'),
(10509, 0, 4, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 2102741, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Jed Runewatcher - On Aggro - Cast ''Defensive Stance'''),
(10509, 0, 5, 0, 0, 0, 100, 0, 8000, 12000, 15000, 20000, 0, 0, 11, 2102840, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Jed Runewatcher - In Combat - Cast ''Berserker Charge'' on Random hostile'),
(10509, 0, 6, 0, 0, 0, 100, 0, 7700, 9700, 8000, 9000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Jed Runewatcher - In Combat - Cast ''Fierce Blow'' on Victim');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10899 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10899, 0, 1, 0, 0, 0, 100, 0, 5000, 7000, 4000, 6000, 0, 0, 11, 15580, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Every 4 - 6 seconds (5 - 7s initially)  - Self: Cast spell Strike (15580) on Victim'),
(10899, 0, 2, 0, 0, 0, 100, 0, 5000, 10000, 20000, 20000, 0, 0, 11, 16172, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Every 20 - 20 seconds (5 - 10s initially)  - Self: Cast spell Head Crack (16172) on Victim'),
(10899, 0, 3, 0, 0, 0, 100, 0, 10000, 10000, 10000, 10000, 0, 0, 11, 6253, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Every 10 seconds  - Self: Cast spell Backhand (6253) on Victim'),
(10899, 0, 4, 0, 0, 0, 100, 0, 8000, 10000, 12000, 16000, 0, 0, 11, 2102553, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Goraluk Anvilcrack - In Combat - Cast ''Stunning Strike'' on Victim'),
(10899, 0, 5, 0, 0, 0, 100, 0, 6000, 6000, 25000, 30000, 0, 0, 11, 2102138, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Goraluk Anvilcrack - In Combat - Cast ''Enchant Armor - Protection V'''),
(10899, 0, 6, 0, 0, 0, 100, 0, 16000, 16000, 25000, 30000, 0, 0, 11, 2102137, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Goraluk Anvilcrack - In Combat - Cast ''Enchant Pickaxe - Efficieny V'''),
(10899, 0, 7, 0, 0, 0, 100, 0, 5000, 7000, 6000, 8000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Goraluk Anvilcrack - In Combat - Cast ''Fierce Blow'' on Victim');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 10814 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10814, 0, 0, 0, 0, 0, 100, 0, 5000, 12800, 13000, 13000, 0, 0, 11, 15708, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Chromatic Elite Guard - In Combat - Cast ''Mortal Strike'' (Normal Dungeon)'),
(10814, 0, 1, 0, 0, 0, 100, 0, 5600, 15400, 11200, 25700, 0, 0, 11, 16790, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Chromatic Elite Guard - In Combat - Cast ''Stunning Strike'' (Normal Dungeon)'),
(10814, 0, 2, 0, 0, 0, 100, 0, 12000, 20800, 9000, 9000, 0, 0, 11, 15580, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Chromatic Elite Guard - In Combat - Cast ''Strike'' (Normal Dungeon)'),
(10814, 0, 3, 0, 0, 0, 100, 0, 5000, 7000, 6000, 8000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Chromatic Elite Guard - In Combat - Cast ''Fierce Blow'' (Normal Dungeon)');

-- General Drakkisath, Pyroguard Emberseer, The Beast and Mr. Smite cast their Ascension abilities in main's scripts.
DELETE FROM `coa_dungeon_boss_kit` WHERE `entry` IN (646, 9816, 10363, 10430);

-- Bouncing Saw Blade is cast by main's Sneed's Shredder kit; it keeps its stock targeting.
DELETE FROM `spell_script_names` WHERE `spell_id` = 2102559 AND `ScriptName` = 'spell_coa_bouncing_saw_blade';
