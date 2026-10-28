-- User-selected native flightmaster icons based on server FactionTemplate faction-group/friendly/hostile masks.
-- Restrict to flightmaster-flagged templates with world spawns; preserve existing icon overrides/disabled rows.

-- Alliance flightmasters.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 937520, 1 FROM `creature_template` `t`
WHERE (`t`.`npcflag` & 8192) <> 0
AND `t`.`faction` IN (12, 55, 80, 84, 534, 694, 894, 1377, 1638, 1732, 1737, 1756, 1892, 2026)
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);

-- Horde flightmasters.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 937518, 1 FROM `creature_template` `t`
WHERE (`t`.`npcflag` & 8192) <> 0
AND `t`.`faction` IN (29, 68, 104, 126, 714, 1074, 1604, 1729, 1735, 1760, 1921, 1922, 1923, 1928, 1929, 1981, 2122)
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);

-- Neutral flightmasters.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 937519, 1 FROM `creature_template` `t`
WHERE (`t`.`npcflag` & 8192) <> 0
AND `t`.`faction` IN (35, 69, 474, 1710, 1743, 1744, 1816, 1960, 2007, 2010, 2050, 2070, 2071, 2107)
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);
