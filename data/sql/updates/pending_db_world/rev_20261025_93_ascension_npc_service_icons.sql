-- Selected service-icon assignments; original Ascension NPC-to-spell assignments are unverified.
-- Preserve existing operator overrides and disabled mappings on rerun.
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `entry`, 420007, 1 FROM `creature_template` WHERE `entry` = 900007;

INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `entry`, 420014, 1 FROM `creature_template` WHERE `entry` IN (57524, 75118);
