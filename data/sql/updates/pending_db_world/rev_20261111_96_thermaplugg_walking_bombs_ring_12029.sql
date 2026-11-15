-- Issue #12029: Mekgineer Thermaplugg's kit Walking Bombs (9780710) spawned at a random point anywhere within
-- 20 yards (SMART_TARGET_RANDOM_POINT picks a uniform radius), often right under the boss. The kit's in-game check
-- (rev_20261002_10_gnomeregan_bombs.sql) places them about 20 yards from him, so each Jackhammer now summons the
-- three bombs on a 20-yard ring around Thermaplugg.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 7800 AND `source_type` = 0 AND `id` BETWEEN 9010 AND 9012;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
    `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(7800, 0, 9010, 9011, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9780710, 1, 40000, 0, 0, 0, 1, 0, 0, 0, 0, 20.0, 0.0, 0.0, 0.0, 'Mekgineer Thermaplugg - Ascension kit - Linked - Summon Creature 9780710 20 yd away (ring 1/3)'),
(7800, 0, 9011, 9012, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9780710, 1, 40000, 0, 0, 0, 1, 0, 0, 0, 0, -10.0, 17.32, 0.0, 0.0, 'Mekgineer Thermaplugg - Ascension kit - Linked - Summon Creature 9780710 20 yd away (ring 2/3)'),
(7800, 0, 9012, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 9780710, 1, 40000, 0, 0, 0, 1, 0, 0, 0, 0, -10.0, -17.32, 0.0, 0.0, 'Mekgineer Thermaplugg - Ascension kit - Linked - Summon Creature 9780710 20 yd away (ring 3/3)');
