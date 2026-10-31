-- User-selected Hearthstone icon for spawned innkeepers; original per-NPC assignments remain unverified.
-- Preserve existing operator overrides and disabled mappings on rerun.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `t`.`entry`, 937517, 1 FROM `creature_template` `t`
WHERE (`t`.`npcflag` & 65536) <> 0
AND EXISTS (SELECT 1 FROM `creature` `c` WHERE `c`.`id` = `t`.`entry`);
