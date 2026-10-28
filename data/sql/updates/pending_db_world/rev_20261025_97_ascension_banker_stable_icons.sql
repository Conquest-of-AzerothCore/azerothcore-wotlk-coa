-- User-selected service icons; original per-NPC Ascension assignments remain unverified.
-- Preserve existing overrides/disabled mappings and exclude conflicting banker/stable-master templates.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 420002, 1 FROM `creature_template` `t`
WHERE (`t`.`npcflag` & 131072) <> 0 AND (`t`.`npcflag` & 4194304) = 0
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);

INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 420001, 1 FROM `creature_template` `t`
WHERE (`t`.`npcflag` & 4194304) <> 0 AND (`t`.`npcflag` & 131072) = 0
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);
