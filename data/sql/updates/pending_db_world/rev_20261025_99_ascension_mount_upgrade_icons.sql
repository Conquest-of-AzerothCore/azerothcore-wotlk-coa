-- User-selected service matches; original per-NPC Ascension assignments remain unverified.
-- Guardian of Time offers broader Worldforged upgrades, not exclusively weapon upgrades.
-- Preserve existing icon overrides and disabled mappings on rerun.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 982754, 1 FROM `creature_template` `t`
WHERE `t`.`entry` IN (384, 1261, 3685, 4730, 32216, 97920, 164592)
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`)
AND EXISTS (SELECT 1 FROM `npc_vendor` `v` WHERE `v`.`entry` = `t`.`entry`);

INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 420005, 1 FROM `creature_template` `t`
WHERE `t`.`entry` = 9780012 AND `t`.`ScriptName` = 'npc_worldforged_guardian'
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);
