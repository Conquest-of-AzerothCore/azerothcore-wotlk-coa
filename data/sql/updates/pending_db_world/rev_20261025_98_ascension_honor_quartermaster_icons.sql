-- User-selected Honor icons for spawned PvP quartermasters with verified Honor-priced stock.
-- FactionTemplate masks establish Alliance/Horde affiliation; preserve existing overrides/disabled mappings.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 420012, 1 FROM `creature_template` `t`
WHERE (`t`.`entry`, `t`.`faction`) IN ((12783, 1078), (13217, 1334), (14753, 1514), (15127, 1599))
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`)
AND EXISTS (SELECT 1 FROM `npc_vendor` `v` WHERE `v`.`entry` = `t`.`entry`);

INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 420011, 1 FROM `creature_template` `t`
WHERE (`t`.`entry`, `t`.`faction`) IN ((12796, 1074), (13219, 1335), (14754, 1515), (15126, 1598))
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`)
AND EXISTS (SELECT 1 FROM `npc_vendor` `v` WHERE `v`.`entry` = `t`.`entry`);
