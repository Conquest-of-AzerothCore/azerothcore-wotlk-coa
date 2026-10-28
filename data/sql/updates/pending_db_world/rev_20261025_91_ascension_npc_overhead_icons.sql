CREATE TABLE IF NOT EXISTS `ascension_npc_overhead_icons` (
  `creature_entry` int unsigned NOT NULL,
  `spell_id` int unsigned NOT NULL,
  `enabled` tinyint unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`creature_entry`),
  CONSTRAINT `chk_ascension_npc_overhead_icons_enabled` CHECK (`enabled` IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Confirmed local Ascension data: Silas Darkmoon has creature_template_addon.auras = '420000'.
-- Keep the existing addon aura and preserve any explicit operator override or disabled row on rerun.
DELETE FROM `ascension_npc_overhead_icons`
WHERE `creature_entry` = 642827 AND `spell_id` = 420000 AND `enabled` = 1;
INSERT IGNORE INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`)
SELECT `entry`, 420000, 1 FROM `creature_template` WHERE `entry` = 642827;
