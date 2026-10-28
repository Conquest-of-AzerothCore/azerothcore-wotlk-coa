-- User-selected Chromie hourglass; original NPC-to-spell assignment remains unverified.
-- Preserve existing operator overrides and disabled mappings on rerun.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `entry`, 498630, 1 FROM `creature_template` WHERE `entry` = 178081;
