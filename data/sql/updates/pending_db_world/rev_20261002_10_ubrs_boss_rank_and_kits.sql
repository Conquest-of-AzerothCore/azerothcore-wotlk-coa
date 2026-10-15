-- Pyroguard Emberseer, Solakar Flamewreath, Jed Runewatcher, Goraluk Anvilcrack and General Drakkisath are
-- bosses (rank 3) in CoA's own creature query cache (hertigservices/ascension-data, conquest-of-azeroth,
-- captured 2026-08-28 to 2026-09-07).
UPDATE `creature_template` SET `rank` = 3 WHERE `entry` IN (9816, 10264, 10363, 10509, 10899);

-- Jed Runewatcher, Chromatic Elite Guard and Goraluk Anvilcrack keep their kits and gain the abilities that
-- Ascension's kits add (db.exil.es/npc/10509, /10814, /10899), which record no timers.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (10509, 10814, 10899) AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`,
    `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`,
    `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
    `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
    `comment`) VALUES
(10509, 0, 0, 0, 37, 0, 85, 512, 0, 0, 0, 0, 0, 0, 41, 500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'On AI initialize - None: Despawn in 0.5 s'),
(10509, 0, 1, 0, 0, 0, 100, 2, 5000, 7000, 4000, 6000, 0, 0, 11, 14516, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Every 4 - 6 seconds (5 - 7s initially)  - Self: Cast spell Strike (14516) on Victim'),
(10509, 0, 2, 0, 105, 0, 100, 2, 10000, 10000, 10000, 10000, 0, 5, 11, 11972, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Every 10 seconds  - Self: Cast spell Shield Bash (11972) on Victim'),
(10509, 0, 3, 0, 0, 0, 100, 2, 10000, 10000, 5000, 15000, 0, 0, 11, 15749, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Every 5 - 15 seconds (10 - 10s initially)  - Self: Cast spell Shield Charge (15749) on Random hostile'),
(10509, 0, 4, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 2102741, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jed Runewatcher - On Aggro - Cast ''Defensive Stance'''),
(10509, 0, 5, 0, 0, 0, 100, 2, 8000, 12000, 15000, 20000, 0, 0, 11, 2102840, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Jed Runewatcher - In Combat - Cast ''Berserker Charge'' on Random hostile'),
(10509, 0, 6, 0, 0, 0, 100, 2, 5000, 7000, 6000, 8000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Jed Runewatcher - In Combat - Cast ''Fierce Blow'' on Victim'),
(10814, 0, 0, 0, 0, 0, 100, 2, 5000, 12800, 13000, 13000, 0, 0, 11, 15708, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Chromatic Elite Guard - In Combat - Cast ''Mortal Strike'' (Normal Dungeon)'),
(10814, 0, 1, 0, 0, 0, 100, 2, 5600, 15400, 11200, 25700, 0, 0, 11, 16790, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Chromatic Elite Guard - In Combat - Cast ''Stunning Strike'' (Normal Dungeon)'),
(10814, 0, 2, 0, 0, 0, 100, 2, 12000, 20800, 9000, 9000, 0, 0, 11, 15580, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Chromatic Elite Guard - In Combat - Cast ''Strike'' (Normal Dungeon)'),
(10814, 0, 3, 0, 0, 0, 100, 2, 5000, 7000, 6000, 8000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Chromatic Elite Guard - In Combat - Cast ''Fierce Blow'' (Normal Dungeon)'),
(10899, 0, 1, 0, 0, 0, 100, 2, 5000, 7000, 4000, 6000, 0, 0, 11, 15580, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Every 4 - 6 seconds (5 - 7s initially)  - Self: Cast spell Strike (15580) on Victim'),
(10899, 0, 2, 0, 0, 0, 100, 2, 5000, 10000, 20000, 20000, 0, 0, 11, 16172, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Every 20 - 20 seconds (5 - 10s initially)  - Self: Cast spell Head Crack (16172) on Victim'),
(10899, 0, 3, 0, 0, 0, 100, 2, 10000, 10000, 10000, 10000, 0, 0, 11, 6253, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Every 10 seconds  - Self: Cast spell Backhand (6253) on Victim'),
(10899, 0, 4, 0, 0, 0, 100, 2, 8000, 10000, 12000, 16000, 0, 0, 11, 2102553, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Goraluk Anvilcrack - In Combat - Cast ''Stunning Strike'' on Victim'),
(10899, 0, 5, 0, 0, 0, 100, 2, 6000, 6000, 25000, 30000, 0, 0, 11, 2102138, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Goraluk Anvilcrack - In Combat - Cast ''Enchant Armor - Protection V'''),
(10899, 0, 6, 0, 0, 0, 100, 2, 16000, 16000, 25000, 30000, 0, 0, 11, 2102137, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Goraluk Anvilcrack - In Combat - Cast ''Enchant Pickaxe - Efficieny V'''),
(10899, 0, 7, 0, 0, 0, 100, 2, 5000, 7000, 6000, 8000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Goraluk Anvilcrack - In Combat - Cast ''Fierce Blow'' on Victim');
